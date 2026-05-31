class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Must be logged in everywhere except on Devise pages (login, sign up, etc.)
  before_action :authenticate_user!, unless: :devise_controller?

  # Scope every query to the current user's store (acts_as_tenant)
  set_current_tenant_through_filter
  before_action :set_current_tenant

  # Turn a failed permission check into a friendly redirect instead of a 500
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_current_tenant
    ActsAsTenant.current_tenant = current_user&.tenant
  end

  def user_not_authorized
    flash[:alert] = "You are not allowed to do that."
    redirect_back fallback_location: root_path
  end
end
