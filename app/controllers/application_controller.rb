class ApplicationController < ActionController::Base
  include Auth
  include Ip

  def sign_out
    reset_session
    redirect_to logout_url.to_s
  end

  private

  def logout_url
    domain = ENV["AUTH0_DOMAIN"]
    client_id = ENV["AUTH0_CLIENT_ID"]
    request_params = {
      returnTo: root_url,
      client_id: client_id,
    }

    URI::HTTPS.build(host: domain, path: "/v2/logout", query: to_query(request_params))
  end

  def to_query(hash)
    hash.map { |k, v| "#{k}=#{CGI.escape(v)}" unless v.nil? }.reject(&:nil?).join("&")
  end

  def append_info_to_payload(payload)
    super
    payload[:remote_ip] = request_ip
  end

  def add_breadcrumb(name, path, options = {})
    super name, path, options.merge(title: name)
  end
end
