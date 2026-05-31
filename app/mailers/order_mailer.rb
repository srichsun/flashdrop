class OrderMailer < ApplicationMailer
  # Let the store owner know a new order has been paid
  def paid_notification(order)
    @order = order
    owner = order.tenant.users.owner.first
    mail(to: owner.email, subject: "Order ##{order.id} was paid")
  end
end
