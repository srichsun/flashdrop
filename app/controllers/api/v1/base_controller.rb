module Api
  module V1
    # JSON API base: authenticates via a Bearer JWT and scopes to that user's store.
    class BaseController < ActionController::API
      before_action :authenticate_api_user!

      attr_reader :current_user

      private

      def authenticate_api_user!
        token = request.headers["Authorization"].to_s.split.last
        payload = JsonWebToken.decode(token)
        @current_user = User.find_by(id: payload&.dig("user_id"))
        return render(json: { error: "unauthorized" }, status: :unauthorized) unless @current_user

        ActsAsTenant.current_tenant = @current_user.tenant
      end
    end
  end
end
