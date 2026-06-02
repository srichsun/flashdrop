# Signs and verifies the JWTs used by the REST API.
class JsonWebToken
  ALGORITHM = "HS256".freeze

  class << self
    def encode(payload, exp: 24.hours.from_now)
      JWT.encode(payload.merge(exp: exp.to_i), secret, ALGORITHM)
    end

    def decode(token)
      JWT.decode(token, secret, true, algorithm: ALGORITHM).first
    rescue JWT::DecodeError
      nil
    end

    private

    def secret
      Rails.application.secret_key_base
    end
  end
end
