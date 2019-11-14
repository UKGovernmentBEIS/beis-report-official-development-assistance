class Staff::BaseController < ApplicationController
  include Secured

  helper_method :current_user
  def current_user
    @current_user ||= User.where(identifier: signed_in_user_identifier).first_or_create! { |user|
      user.name = session.dig(:userinfo, "info", "name")
      user.email = session.dig(:userinfo, "info", "email")
    }
  end

  def sign_out
    reset_session
    redirect_to root_path
  end

  def signed_in_user_identifier
    session.dig(:userinfo, "uid")
  end
end
