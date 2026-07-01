# AI customer-service agent for the storefront chat.
#
# Runs an LLM tool-use loop: the model decides which tool to call, we run it,
# feed the result back, and repeat until it has a final answer. Every tool reads
# ONLY the current store's data — acts_as_tenant auto-scopes each query, so a
# customer can never read another store's orders or products.
class CustomerServiceAgent
  MODEL = "claude-opus-4-8"

  # Human-readable order states for the customer-facing reply.
  ORDER_STATUS = {
    "pending" => "待付款",
    "paid" => "已付款",
    "shipped" => "已出貨",
    "cancelled" => "已取消"
  }.freeze

  RETURN_POLICY = <<~TEXT.chomp
    收到商品後 7 天內可申請退換貨，商品需保持全新未使用。
    在會員中心點「我的訂單 → 申請退貨」即可，物流由我們安排上門收件。
  TEXT

  SYSTEM = <<~TEXT.chomp
    你是電商客服助理。用繁體中文、親切又簡潔地回覆客人。
    需要訂單、庫存、退換貨資訊時，一律呼叫提供的工具查詢，不要自己編造。
  TEXT

  # Tool schemas described to the model (function calling).
  TOOLS = [
    {
      name: "get_order",
      description: "查詢單一訂單的狀態與內容。需要訂單編號。",
      input_schema: {
        type: "object",
        properties: { order_id: { type: "string", description: "訂單編號" } },
        required: [ "order_id" ]
      }
    },
    {
      name: "get_inventory",
      description: "查詢某項商品目前的庫存。需要商品名稱。",
      input_schema: {
        type: "object",
        properties: { product_name: { type: "string", description: "商品名稱" } },
        required: [ "product_name" ]
      }
    },
    {
      name: "get_return_policy",
      description: "查詢退換貨政策。不需要參數。",
      input_schema: { type: "object", properties: {} }
    }
  ].freeze

  def initialize(client: Anthropic::Client.new)
    @client = client
  end

  # Run the agent loop and return the assistant's final reply text.
  def respond(question)
    messages = [ { role: "user", content: question } ]

    loop do
      response = @client.messages.create(
        model: MODEL,
        max_tokens: 1024,
        system: SYSTEM,
        tools: TOOLS,
        messages: messages
      )
      messages << { role: "assistant", content: response.content.map(&:to_h) }

      # No more tool calls -> this is the final answer.
      return final_text(response) unless response.stop_reason == :tool_use

      # The model picked tools; we execute them and feed the results back.
      results = response.content.filter_map do |block|
        next unless block.type == :tool_use

        { type: "tool_result",
          tool_use_id: block.id,
          content: run_tool(block.name, block.input) }
      end
      messages << { role: "user", content: results }
    end
  end

  # --- Tools (tenant-scoped by acts_as_tenant) ---

  def get_order(order_id)
    order = Order.find_by(id: order_id)
    return "查無此訂單編號：#{order_id}" unless order

    "訂單 ##{order.id}：#{order.product.name} x#{order.quantity}，" \
      "狀態 #{ORDER_STATUS.fetch(order.aasm_state, order.aasm_state)}，" \
      "金額 NT$#{order.total_cents / 100}"
  end

  def get_inventory(product_name)
    product = Product.search_by_name(product_name).first
    return "查無此商品：#{product_name}" unless product

    if product.stock.positive?
      "「#{product.name}」目前庫存 #{product.stock} 件"
    else
      "「#{product.name}」目前缺貨"
    end
  end

  def get_return_policy(*)
    RETURN_POLICY
  end

  private

  # Dispatch a tool call from the model to the matching Ruby method.
  def run_tool(name, input)
    params = input.to_h.transform_keys(&:to_s)
    case name.to_s
    when "get_order"         then get_order(params["order_id"])
    when "get_inventory"     then get_inventory(params["product_name"])
    when "get_return_policy" then get_return_policy
    else "未知的工具：#{name}"
    end
  end

  def final_text(response)
    response.content.select { |block| block.type == :text }.map(&:text).join
  end
end
