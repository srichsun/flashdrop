class OrdersController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @pagy, @orders = pagy(policy_scope(Order).order(created_at: :desc), limit: 10)
  end

  def ship
    order = authorize Order.find(params[:id])
    order.ship! if order.may_ship?
    redirect_to orders_path, notice: "Order ##{order.id} marked shipped."
  end
end
