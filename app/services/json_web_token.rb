# JWT token encoding/decoding service
# Handles JWT generation, validation, and expiration
class JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base.to_s
  
  # Encode user data into JWT token
  # @param payload [Hash] User data to encode (typically {user_id: id})
  # @param exp [Time] Expiration time (default: 24 hours from now)
  # @return [String] JWT token
  # @example
  #   token = JsonWebToken.encode(user_id: 123)
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end
  
  # Decode JWT token into user data
  # @param token [String] JWT token to decode
  # @return [HashWithIndifferentAccess, nil] Decoded payload or nil if invalid/expired
  # @example
  #   decoded = JsonWebToken.decode(token)
  #   user_id = decoded[:user_id] if decoded
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    Rails.logger.warn "JWT decode failed: #{e.message}"
    nil
  end
end

