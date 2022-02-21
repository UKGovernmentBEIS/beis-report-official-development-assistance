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
  before_action :configure_sign_in_params, only: :create

  prepend_before_action :authenticate_with_otp_two_factor,
    if: -> { action_name == "create" && otp_two_factor_enabled? }

  protect_from_forgery with: :exception, prepend: true, except: :destroy

  protected

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

  def user_params
    params.require(:user).permit(:email, :password, :remember_me, :otp_attempt)
  end

  def valid_otp_attempt?(user)
    user.validate_and_consume_otp!(user_params[:otp_attempt])
  end

  def authenticate_with_otp_two_factor
    user = self.resource = find_user

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      authenticate_user_with_otp_two_factor(user)
    elsif user&.valid_password?(user_params[:password])
      send_otp(user) if user.mobile_number

      prompt_for_otp_two_factor(user)
    end
  end

  def authenticate_user_with_otp_two_factor(user)
    if valid_otp_attempt?(user)
      # Remove any lingering user data from login
      session.delete(:otp_user_id)

      remember_me(user) if user_params[:remember_me] == "1"
      user.save!
      sign_in(user, event: :authentication)
    else
      flash.now[:alert] = t("devise.failure.invalid_two_factor")
      prompt_for_otp_two_factor(user)
    end
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  def find_user
    if session[:otp_user_id]
      User.find(session[:otp_user_id])
    elsif user_params[:email]
      User.find_by(email: user_params[:email])
    end
  end

  def otp_two_factor_enabled?
    find_user&.otp_required_for_login
  end

  def prompt_for_otp_two_factor(user)
    @user = user

    session[:otp_user_id] = user.id
    render "devise/sessions/two_factor"
  end

  def send_otp(user)
    Notify::OTPMessage.new(user.mobile_number, user.current_otp).deliver
  end
end
