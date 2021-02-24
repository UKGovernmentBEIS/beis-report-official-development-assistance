module Secured
  extend ActiveSupport::Concern

  included do
    before_action :logged_in_using_omniauth?
  end

  def logged_in_using_omniauth?
    # DEBUG: Session info can be missing
    if Rails.env.production? && session[:userinfo].blank?
      # Is there a session object?
      Rails.logger.info(session)

      # Are there any keys?
      Rails.logger.info(session.keys)

      # Is Redis available as a session_store?
      Rails.logger.info(Redis.new(url: ENV["REDIS_URL"]).ping)
    end

    if session[:userinfo].blank?
      session[:redirect_path] = request.env["PATH_INFO"]
      redirect_to "/"
    end
  end
end
