require "rails_helper"

# These specs exercise the tenant-scoped tools directly — no LLM calls, so the
# Anthropic client is a stub. The point is to prove the tools read only the
# current store's data and format the customer-facing reply correctly.
RSpec.describe CustomerServiceAgent do
  subject(:agent) { described_class.new(client: instance_double(Anthropic::Client)) }

  let(:store) { create(:tenant) }

  # Runs after rails_helper's global "reset tenant to nil", so the store sticks
  # as the current tenant for the whole example.
  before { ActsAsTenant.current_tenant = store }

  describe "#get_order" do
    it "returns the status of an order in the current store" do
      product = create(:product, tenant: store, name: "黑色外套")
      order = create(:order, tenant: store, product: product, quantity: 2)

      expect(agent.get_order(order.id)).to include("黑色外套", "x2", "待付款")
    end

    it "does not leak an order that belongs to another store" do
      other = create(:tenant)
      foreign_order = ActsAsTenant.with_tenant(other) { create(:order, tenant: other) }

      expect(agent.get_order(foreign_order.id)).to eq("查無此訂單編號：#{foreign_order.id}")
    end

    it "reports when the order number does not exist" do
      expect(agent.get_order(999_999)).to eq("查無此訂單編號：999999")
    end
  end

  describe "#get_inventory" do
    it "reports the stock level" do
      create(:product, tenant: store, name: "帽子", stock: 4)

      expect(agent.get_inventory("帽子")).to eq("「帽子」目前庫存 4 件")
    end

    it "reports out of stock" do
      create(:product, tenant: store, name: "手套", stock: 0)

      expect(agent.get_inventory("手套")).to eq("「手套」目前缺貨")
    end

    it "does not leak a product from another store" do
      other = create(:tenant)
      ActsAsTenant.with_tenant(other) { create(:product, tenant: other, name: "圍巾", stock: 5) }

      expect(agent.get_inventory("圍巾")).to eq("查無此商品：圍巾")
    end
  end

  describe "#get_return_policy" do
    it "returns the policy text" do
      expect(agent.get_return_policy).to include("7 天內")
    end
  end

  describe "#respond loop cap" do
    it "bails after MAX_TURNS if the model never stops calling tools" do
      tool_block = double(type: :tool_use, id: "t", name: "get_return_policy", input: {})
      looping = double(content: [ tool_block ], stop_reason: :tool_use)
      messages_api = instance_double(Anthropic::Resources::Messages, create: looping)
      agent = described_class.new(client: double(messages: messages_api))

      expect(agent.respond("hi")).to include("複雜")
      expect(messages_api).to have_received(:create).exactly(described_class::MAX_TURNS).times
    end
  end

  describe "echoing the assistant turn back" do
    # The SDK's tool_use block carries an extra caller_ field the API rejects if
    # sent back verbatim; we must rebuild the turn with only accepted fields.
    it "keeps only API-accepted fields on each block" do
      text = double(type: :text, text: "hi")
      tool = double(type: :tool_use, id: "t1", name: "get_order", input: { "order_id" => "1" })
      response = double(content: [ text, tool ])

      expect(agent.send(:assistant_content, response)).to eq([
        { type: "text", text: "hi" },
        { type: "tool_use", id: "t1", name: "get_order", input: { "order_id" => "1" } }
      ])
    end
  end
end
