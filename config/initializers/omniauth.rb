Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, Rails.application.credentials.dig(:github, :client_id) || ENV["GITHUB_CLIENT_ID"],
                     Rails.application.credentials.dig(:github, :client_secret) || ENV["GITHUB_CLIENT_SECRET"]
end

OmniAuth.config.allowed_request_methods = [ :post ]
