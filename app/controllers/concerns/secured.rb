module Secured
  extend ActiveSupport::Concern

  included do
    before_action :redirect_unauthenticated
  end

  def redirect_unauthenticated
    if !authenticated?
      session[:redirect_path] = request.env["PATH_INFO"]
      redirect_to "/"
    end
  end
end
