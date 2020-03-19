class Auth0Controller < ApplicationController
  def callback
    # This stores all the user information that came from Auth0
    # and the IdP
    session[:userinfo] = request.env["omniauth.auth"]

    # Redirect to the URL you want after successful auth
    if current_user.active && current_user.organisation
      redirect_to organisation_path(current_user.organisation)
    else
      render "pages/errors/not_authorised",
        status: 401,
        locals: {error_message: I18n.t("page_content.errors.not_authorised.explanation")}
    end
  end

  def failure
    message = request.params["message"]
    @error_message = t message.to_sym,
      scope: "page_content.errors.auth0.error_messages",
      raise: true
  rescue I18n::MissingTranslationData
    Rollbar.log(:info, "Unknown response from Auth0", message)
    @error_message = t("page_content.errors.auth0.error_messages.generic")
  end
end
