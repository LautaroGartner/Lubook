class Rack::Attack
  # Throttle login attempts by IP
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Throttle login attempts by email
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email").to_s.downcase.presence
    end
  end

  # Throttle signups by IP
  throttle("signups/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/users" && req.post?
  end

  # Block obvious bad actors
  blocklist("block bad UAs") do |req|
    req.user_agent.to_s.match?(/curl|wget|scanner/i) && Rails.env.production?
  end

  self.throttled_responder = lambda do |_req|
    [ 429, { "Content-Type" => "text/plain" }, [ "Too many requests. Slow down." ] ]
  end
end
