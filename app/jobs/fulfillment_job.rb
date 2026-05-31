# Second link in the chain: prepare the order for shipping. Kept simple for now
# (real fulfillment integration would go here); Sidekiq retries it on failure.
class FulfillmentJob < ApplicationJob
  queue_as :default

  def perform(order)
    Rails.logger.info("Order ##{order.id} queued for fulfillment")
  end
end
