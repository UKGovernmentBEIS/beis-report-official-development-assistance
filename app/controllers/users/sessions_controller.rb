# frozen_string_literal: true

require "notify/otp_message"

##
# Override the default Devise implementation in order to implement two-phase MFA:
#
# 1. Log in with user name and password
# 2. Supply an OTP (sent separately) to complete the log in
#
# Much of this is taken from step 4 of
# https://www.jamesridgway.co.uk/implementing-a-two-step-otp-u2f-login-workflow-with-rails-and-devise/
class Users::SessionsController < Devise::SessionsController
  prepend_before_action :handle_mfa_flow, if: -> { action_name == "create" && otp_two_factor_enabled? }

  protect_from_forgery with: :exception, prepend: true, except: :destroy

  def edit_mobile_number
    self.resource = find_user
    render "devise/sessions/mobile_number"
  end

  protected

  # Given a login +mfa_phase+, take the appropriate action.
  def handle_mfa_flow
    case mfa_phase
    when :needs_mobile_number then prompt_for "mobile_number"
    when :has_mobile_number then send_and_prompt_for_otp
    when :updating_mobile_number
      user.update!(mobile_number: user_params[:mobile_number])
      send_and_prompt_for_otp
    when :validating_otp then complete_sign_in_with_otp? || prompt_for("otp_attempt")
    end
  end

  def mfa_phase
    if user_params[:otp_attempt] && session[:otp_user_id]
      :validating_otp
    elsif user_params[:mobile_number] && session[:otp_user_id]
      :updating_mobile_number
    elsif user&.valid_password?(user_params[:password])
      user.mobile_number.nil? ? :needs_mobile_number : :has_mobile_number
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :remember_me, :otp_attempt, :mobile_number)
  end

  def valid_otp_attempt?
    user.validate_and_consume_otp!(user_params[:otp_attempt])
  end

  # Attempt to verify and consume the current sign-in OTP to prevent reuse.
  # @return true if successful, false otherwise
  def complete_sign_in_with_otp?
    if valid_otp_attempt?
      # Remove any lingering user data from login
      session.delete(:otp_user_id)

      remember_me(user) if user_params[:remember_me] == "1"
      user.mobile_number_confirmed_at ||= Time.zone.now
      user.save!

      sign_in(user, event: :authentication)
      true
    else
      flash.now[:alert] = t("devise.failure.invalid_two_factor")
      false
    end
  end

  def user
    @user ||= (self.resource = find_user)
  end

  # First time through on login, we find on email. Thereafter, we have the otp_user_id
  # in session. When we successfully auth via +complete_sign_in_with_otp?+ we remove that otp_user_id.
  def find_user
    if session[:otp_user_id]
      User.find(session[:otp_user_id])
    elsif user_params[:email]
      User.find_by(email: user_params[:email]).tap do |user|
        session[:otp_user_id] = user&.id
      end
    end
  end

  def otp_two_factor_enabled?
    user&.otp_required_for_login
  end

  def prompt_for(template)
    render "devise/sessions/#{template}"
  end

  def send_and_prompt_for_otp
    Notify::OTPMessage.new(user.mobile_number, user.current_otp).deliver
    prompt_for "otp_attempt"
  end

  # we also need to completely override Devise's require_no_authentication such that
  # we don't display an "already signed in" message instead of "signed in successfully".
  #
  # This is a complete copy of Devise::SessionsController#require_no_authentication with
  # a check for a current :otp_attempt.
  def require_no_authentication
    assert_is_devise_resource!
    return unless is_navigational_format?
    no_input = devise_mapping.no_input_strategies

    authenticated = if no_input.present?
      args = no_input.dup.push scope: resource_name
      warden.authenticate?(*args)
    else
      warden.authenticated?(resource_name)
    end

    if authenticated && (resource = warden.user(resource_name)) && params.dig(:user, :otp_attempt).nil?
      set_flash_message(:alert, "already_authenticated", scope: "devise.failure")
      redirect_to after_sign_in_path_for(resource)
    end
  end
end
