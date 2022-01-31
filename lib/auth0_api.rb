require "uri"
require "net/http"
require "auth0"

class Auth0Api
  def client
    @client ||= new_client
  end

  def token
    @token ||= token_data["access_token"]
  end

  private

  def new_client
    Auth0Client.new(
      client_id: ENV["AUTH0_CLIENT_ID"],
      domain: ENV["AUTH0_DOMAIN"],
      token: token,
      api_version: 2
    )
  end

  def token_data
    url = URI("https://#{ENV["AUTH0_DOMAIN"]}/oauth/token")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["content-type"] = "application/json"
    request.body = JSON.dump(
      grant_type: "client_credentials",
      client_id: ENV["AUTH0_CLIENT_ID"],
      client_secret: ENV["AUTH0_CLIENT_SECRET"],
      audience: "https://#{ENV["AUTH0_DOMAIN"]}/api/v2/"
    )
    response = http.request(request)
    JSON.parse(response.read_body)
  end
end
