# frozen_string_literal: true

# AI 客服助理 MVP
# 核心 = 腦(LLM) + 手(工具) + 迴圈(agent loop)
#
# Run:
#   gem install anthropic
#   export ANTHROPIC_API_KEY=sk-...
#   ruby customer_service_agent.rb
#   ruby customer_service_agent.rb "我要問的問題"

require "anthropic"

MODEL = :"claude-opus-4-8" # switch to :"claude-haiku-4-5" for cheaper testing

# --- 手：三個工具（先用假資料，之後換成真的 MerchantOS query 即可） ---

ORDERS = {
  "12345" => { status: "已出貨", item: "黑色外套", eta: "預計明天下午到貨" }
}.freeze

INVENTORY = {
  "外套" => 4,
  "帽子" => 0
}.freeze

RETURN_POLICY = <<~TEXT.chomp
  收到商品後 7 天內可申請退換貨，商品需保持全新未使用。
  在會員中心點「我的訂單 → 申請退貨」即可，物流由我們安排上門收件。
TEXT

def get_order(order_id)
  order = ORDERS[order_id.to_s]
  return "查無此訂單編號：#{order_id}" unless order

  "訂單 #{order_id}：#{order[:item]}，狀態 #{order[:status]}，#{order[:eta]}"
end

def get_inventory(item_name)
  qty = INVENTORY[item_name.to_s]
  return "查無此商品：#{item_name}" if qty.nil?

  qty.positive? ? "「#{item_name}」目前庫存 #{qty} 件" : "「#{item_name}」目前缺貨"
end

def get_return_policy(_input = nil)
  RETURN_POLICY
end

# --- 把工具「描述」給 LLM 聽（tool / function calling） ---

TOOLS = [
  {
    name: "get_order",
    description: "查詢單一訂單的狀態與到貨時間。需要訂單編號。",
    input_schema: {
      type: "object",
      properties: { order_id: { type: "string", description: "訂單編號，例如 12345" } },
      required: ["order_id"]
    }
  },
  {
    name: "get_inventory",
    description: "查詢某項商品目前的庫存數量。需要商品名稱。",
    input_schema: {
      type: "object",
      properties: { item_name: { type: "string", description: "商品名稱，例如 外套" } },
      required: ["item_name"]
    }
  },
  {
    name: "get_return_policy",
    description: "查詢退換貨政策。不需要參數。",
    input_schema: { type: "object", properties: {} }
  }
].freeze

SYSTEM = <<~TEXT.chomp
  你是電商客服助理。用繁體中文、親切又簡潔地回覆客人。
  需要訂單、庫存、退換貨資訊時，一律呼叫提供的工具查詢，不要自己編造。
TEXT

# Dispatch a tool call from the LLM to the real Ruby method.
def run_tool(name, input)
  params = input.to_h.transform_keys(&:to_s)
  case name.to_s
  when "get_order"         then get_order(params["order_id"])
  when "get_inventory"     then get_inventory(params["item_name"])
  when "get_return_policy" then get_return_policy
  else "未知的工具：#{name}"
  end
end

# --- 腦 + 迴圈：這就是 agent loop ---

def run_agent(client, question)
  messages = [{ role: "user", content: question }]
  round = 0

  loop do
    round += 1
    puts "── 回合 #{round}：問 LLM ──"

    response = client.messages.create(
      model: MODEL,
      max_tokens: 1024,
      system: SYSTEM,
      tools: TOOLS,
      messages: messages
    )

    # Always echo the assistant turn back into history.
    messages << { role: "assistant", content: response.content.map(&:to_h) }

    if response.stop_reason == :tool_use
      # LLM decided which tools to call — WE execute them, feed results back.
      tool_results = response.content.filter_map do |block|
        next unless block.type == :tool_use

        puts "   agent 決定用工具：#{block.name} #{block.input.to_h}"
        { type: "tool_result",
          tool_use_id: block.id,
          content: run_tool(block.name, block.input) }
      end
      messages << { role: "user", content: tool_results }
    else
      # No more tools — this is the final answer.
      answer = response.content.select { |b| b.type == :text }.map(&:text).join
      puts "\n🤖 客服助理：\n#{answer}"
      break
    end
  end
end

question = ARGV.first || "我上週訂的訂單 12345 到哪了？另外那件外套還有貨嗎？退貨怎麼辦理？"
puts "👤 客人：#{question}\n\n"

run_agent(Anthropic::Client.new, question)
