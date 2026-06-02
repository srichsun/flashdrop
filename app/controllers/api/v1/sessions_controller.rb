module Api
  module V1
    # Exchanges email + password for a JWT.
    class SessionsController < ActionController::API
      def create
        user = User.find_by(email: params[:email])
        if user&.valid_password?(params[:password])
          render json: { token: JsonWebToken.encode({ user_id: user.id }) }
        else
          render json: { error: "invalid email or password" }, status: :unauthorized
        end
      end
    end
  end
end
