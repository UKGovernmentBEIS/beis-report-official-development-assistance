class Auth0Controller < ApplicationController
  def callback
    # This stores all the user information that came from Auth0
    # and the IdP
    session[:userinfo] = request.env["omniauth.auth"]

    # DEBUG: Is the session set correctly on the auth0 callback? Is it ready to
    # read straight away or is there a delay?
    if Rails.env.production?
      Rails.logger.info("* Auth0 callback contained the following id: #{request.env.dig("omniauth.auth", "uid")}")
      Rails.logger.info("** Auth0 callback has been received. The session has an auth0 id of #{session.dig(:userinfo, :uid)}")
    end

    # Redirect to the URL you want after successful auth
    if current_user.active && current_user.organisation
      redirect_path = session[:redirect_path] || organisation_path(current_user.organisation)
      redirect_to redirect_path
    else
      render "pages/errors/not_authorised",
        status: 401,
        locals: {error_message: t("page_content.errors.not_authorised.explanation")}
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
