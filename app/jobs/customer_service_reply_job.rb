# Runs the customer-service agent off the web request and pushes the reply back
# to the browser over ActionCable (Turbo Stream). A job has no request context,
# so we set the tenant explicitly before running the agent — its tool queries
# stay scoped to this store.
class CustomerServiceReplyJob < ApplicationJob
  queue_as :default

  def perform(tenant_id:, conversation_id:, message:, reply_dom_id:)
    tenant = Tenant.find(tenant_id)
    reply = generate_reply(tenant, message)

    # Replace the "查詢中…" placeholder with the reply on the subscriber's page.
    Turbo::StreamsChannel.broadcast_replace_to(
      "storefront_chat", conversation_id,
      target: reply_dom_id,
      partial: "storefront/chat/reply",
      locals: { dom_id: reply_dom_id, text: reply }
    )
  end

  private

  # Never let a failed LLM call leave the customer staring at "查詢中…" — swap in
  # a friendly message and log the cause instead.
  def generate_reply(tenant, message)
    ActsAsTenant.with_tenant(tenant) { CustomerServiceAgent.new.respond(message) }
  rescue StandardError => e
    Rails.logger.error("[CS_AGENT] reply failed: #{e.class} — #{e.message}")
    "抱歉，客服助理暫時無法回覆，請稍後再試。"
  end
end
