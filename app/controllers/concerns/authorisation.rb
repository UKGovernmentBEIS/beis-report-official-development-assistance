class UserNotAuthorised < StandardError; end
module Authorisation
  extend ActiveSupport::Concern

  included do
    helper_method :current_user

    rescue_from(UserNotAuthorised) do
      render "pages/errors/not_authorised", status: 401
    end
  end

  def current_user
    @current_user ||= if session.dig(:userinfo)
      User.find_by!(identifier: signed_in_user_identifier) do |user|
        user.name = session.dig(:userinfo, "info", "name")
        user.email = session.dig(:userinfo, "info", "email")
      end
    end
  rescue ActiveRecord::RecordNotFound
    repudiate!
    raise UserNotAuthorised
  end

  def signed_in_user_identifier
    session.dig(:userinfo, "uid")
  end

  private def repudiate!
    session.delete(:userinfo)
    @current_user = nil
  end
end
