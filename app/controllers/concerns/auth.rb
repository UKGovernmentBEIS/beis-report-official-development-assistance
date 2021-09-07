class UserNotAuthorised < StandardError; end
module Auth
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
    helper_method :authenticated?

    rescue_from(UserNotAuthorised, Pundit::NotAuthorizedError) do |exception|
      error_message = if exception.respond_to?(:policy)
        t("#{exception.policy.class.to_s.underscore}.#{exception.query}", scope: "not_authorised", default: :default)
      else
        t("page_content.errors.not_authorised.explanation")
      end

      render "pages/errors/not_authorised", formats: [:html], status: 401, locals: {error_message: error_message}
    end
  end

  def current_user
    @current_user ||= if session.dig(:userinfo)
      User.active.includes(:organisation).find_by!(identifier: signed_in_user_identifier) do |user|
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

  def authenticated?
    current_user.present?
  end

  private def repudiate!
    session.delete(:userinfo)
    @current_user = nil
  end
end
