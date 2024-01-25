### Prevent Brute-Force Login Attacks ###
# Throttle POST requests to /users/sign_in by IP address
#
# Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
Rack::Attack.throttle("logins/ip", limit: ENV.fetch("LOGIN_ATTEMPTS_COUNT_BEFORE_THROTTLE", 5), period: ENV.fetch("LOGIN_ATTEMPTS_INTERVAL_BEFORE_THROTTLE", 300)) do |request|
  if request.path.start_with?("/users/sign_in") && request.post?
    request.ip
  end
end
