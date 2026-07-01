require "rails_helper"

RSpec.describe CustomerServiceReplyJob do
  let(:store) { create(:tenant, name: "My Shop") }

  it "runs the agent and broadcasts the reply to the conversation stream" do
    allow(CustomerServiceAgent).to receive(:new)
      .and_return(instance_double(CustomerServiceAgent, respond: "訂單已出貨"))

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
      "storefront_chat", "conv-1",
      hash_including(target: "reply_abc", locals: hash_including(text: "訂單已出貨"))
    )

    described_class.perform_now(
      tenant_id: store.id, conversation_id: "conv-1",
      message: "訂單到了嗎", reply_dom_id: "reply_abc"
    )
  end

  it "sets the current tenant while the agent runs" do
    agent = instance_double(CustomerServiceAgent)
    allow(CustomerServiceAgent).to receive(:new).and_return(agent)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

    expect(agent).to receive(:respond) do |_message|
      expect(ActsAsTenant.current_tenant).to eq(store)
      "ok"
    end

    described_class.perform_now(
      tenant_id: store.id, conversation_id: "c", message: "hi", reply_dom_id: "r"
    )
  end
end
