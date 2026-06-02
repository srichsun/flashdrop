# First link in the post-payment chain: email the store, then hand off to fulfillment.
class NotifyStoreJob < ApplicationJob
  queue_as :default

  def perform(order)
    deliver("owner notification", OrderMailer.paid_notification(order))
    deliver("customer confirmation", OrderMailer.customer_confirmation(order)) if order.customer_email.present?
    FulfillmentJob.perform_later(order)
  end

  private

  # Send one email and log the outcome so delivery problems are visible in the
  # logs (search "[MAIL]") instead of failing silently. A mail failure is logged
  # but doesn't break the rest of the chain.
  def deliver(label, message)
    message.deliver_now
    Rails.logger.info("[MAIL] sent #{label} to #{Array(message.to).join(', ')}")
  rescue StandardError => e
    Rails.logger.error("[MAIL] failed #{label}: #{e.class} — #{e.message}")
  end
end
