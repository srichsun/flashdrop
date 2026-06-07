module Api
  module V1
    # Issues, refreshes and revokes the API's tokens.
    #
    # Pattern: a short-lived stateless access JWT + a long-lived, DB-backed
    # (revocable) refresh token. The refresh token is single-use — each call
    # rotates it — and replaying an already-rotated token triggers a family-wide
    # revoke (theft cut-off).
    class SessionsController < ActionController::API
      ACCESS_TTL = 15.minutes

      # POST /api/v1/login — email + password -> access + refresh
      def create
        user = User.find_by(email: params[:email])
        if user&.valid_password?(params[:password])
          render json: issue_tokens(user)
        else
          render json: { error: "invalid email or password" }, status: :unauthorized
        end
      end

      # POST /api/v1/refresh — swap a valid refresh token for a fresh pair
      def refresh
        token = RefreshToken.find_by_raw(params[:refresh_token])

        if token.nil? || token.expires_at.past?
          return render json: { error: "invalid refresh token" }, status: :unauthorized
        end

        # An already-rotated token is being replayed -> likely stolen. Revoke
        # every active token for that user as a safety cut-off.
        if token.revoked?
          revoke_all(token.user)
          return render json: { error: "refresh token reuse detected" }, status: :unauthorized
        end

        token.revoke! # single-use: this one is now spent
        render json: issue_tokens(token.user)
      end

      # DELETE /api/v1/logout — revoke this device's refresh token
      def destroy
        RefreshToken.find_by_raw(params[:refresh_token])&.revoke!
        head :no_content
      end

      # DELETE /api/v1/logout_all — revoke every refresh token for the user
      def destroy_all
        token = RefreshToken.find_by_raw(params[:refresh_token])
        revoke_all(token.user) if token
        head :no_content
      end

      private

      def issue_tokens(user)
        _record, raw_refresh = RefreshToken.issue(user, user_agent: request.user_agent)
        {
          access_token: JsonWebToken.encode({ user_id: user.id }, exp: ACCESS_TTL.from_now),
          refresh_token: raw_refresh,
          token_type: "Bearer",
          expires_in: ACCESS_TTL.to_i
        }
      end

      def revoke_all(user)
        user.refresh_tokens.where(revoked_at: nil).update_all(revoked_at: Time.current)
      end
    end
  end
end
