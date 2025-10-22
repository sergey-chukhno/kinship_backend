# Configure CORS for React frontend
# Allows React apps to make requests to our Rails API from different origins

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Development: Allow any localhost (flexible for different ports)
    if Rails.env.development?
      origins(/localhost:\d+/, /127\.0\.0\.1:\d+/)
    elsif Rails.env.staging?
      origins ENV['FRONTEND_URL_STAGING'] || 'https://staging.kinship.fr'
    else
      origins ENV['FRONTEND_URL'] || 'https://kinship.fr'
    end
    
    # Allow API requests with credentials
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['Authorization']
  end
end

