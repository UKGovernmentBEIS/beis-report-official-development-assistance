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
    # show a failure page or redirect to an error page
    @error_message = request.params["message"]
  end
end
