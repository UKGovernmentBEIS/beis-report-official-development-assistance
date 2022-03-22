module Auth
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
    helper_method :authenticated?

    rescue_from(Pundit::NotAuthorizedError) do |exception|
      error_message = t("page_content.errors.not_authorised.explanation")
      render "pages/errors/not_authorised", formats: [:html], status: 401, locals: {error_message: error_message}
    end
  end

  def signed_in_user_identifier
    session.dig(:userinfo, "uid")
  end

  def authenticated?
    current_user.present?
  end

  def after_sign_in_path_for(_user)
    session[:redirect_path] || home_path
  end
end
