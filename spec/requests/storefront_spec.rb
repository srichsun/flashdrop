require "rails_helper"

RSpec.describe "Storefront", type: :request do
  let(:store) { create(:tenant, name: "Demo Store") }

  describe "GET /s/:slug" do
    it "is public (no login) and shows in-stock products" do
      in_stock = create(:product, tenant: store, name: "Mug", stock: 5)
      sold_out = create(:product, tenant: store, name: "Tote", stock: 0)

      get storefront_store_path(store)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(in_stock.name)
      expect(response.body).not_to include(sold_out.name)
    end

    it "shows only this store's products" do
      mine = create(:product, tenant: store, name: "My Mug", stock: 5)
      theirs = create(:product, tenant: create(:tenant), name: "Their Mug", stock: 5)

      get storefront_store_path(store)

      expect(response.body).to include(mine.name)
      expect(response.body).not_to include(theirs.name)
    end

    it "shows the product photo when one is attached" do
      product = create(:product, tenant: store, name: "Photo Mug", stock: 5)
      product.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample_product.jpg")),
        filename: "sample_product.jpg", content_type: "image/jpeg"
      )

      get storefront_store_path(store)

      expect(response.body).to match(%r{<img[^>]+rails/active_storage})
    end

    it "filters by the search query" do
      create(:product, tenant: store, name: "Ceramic Mug", stock: 5)
      create(:product, tenant: store, name: "Wooden Spoon", stock: 5)

      get storefront_store_path(store), params: { q: "ceramic" }

      expect(response.body).to include("Ceramic Mug")
      expect(response.body).not_to include("Wooden Spoon")
    end
  end

  describe "GET /s/:slug/checkout/:product_id" do
    it "shows the checkout form" do
      product = create(:product, tenant: store, name: "Mug", stock: 5)

      get storefront_store_checkout_path(store, product.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Checkout", product.name)
    end
  end

  describe "POST /s/:slug/orders" do
    it "creates a pending order and hands off to ECPay" do
      product = create(:product, tenant: store, stock: 3)

      expect do
        post storefront_store_orders_path(store, product_id: product.id,
          order: { quantity: 1, customer_email: "buyer@example.com" })
      end.to change { store.orders.where(aasm_state: "pending").count }.by(1)

      order = store.orders.last
      expect(order.customer_email).to eq("buyer@example.com")
      expect(order.payment_ref).to be_present
      expect(response.body).to include(Ecpay.checkout_url) # auto-submit form action
    end
  end
end
