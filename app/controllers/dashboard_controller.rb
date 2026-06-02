# Landing page after login. Shows the store and its recent sales, which update
# live over ActionCable (Turbo Streams) when an order is paid.
class DashboardController < ApplicationController
  def show
    @tenant = current_user.tenant
    @orders = @tenant.orders.where(aasm_state: %w[paid shipped]).order(created_at: :desc).limit(10)
  end
end
