require "rails_helper"

RSpec.describe "Orders (admin)", type: :request do
  let(:tenant) { create(:tenant) }
  let(:owner) { create(:user, tenant: tenant, role: :owner) }

  it "paginates the store's orders" do
    create_list(:order, 12, tenant: tenant, product: create(:product, tenant: tenant))
    sign_in owner

    get orders_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("pagy") # nav rendered -> more than one page

    get orders_path(page: 2)
    expect(response).to have_http_status(:ok)
  end

  it "only shows the current store's orders" do
    create(:order, tenant: tenant, product: create(:product, tenant: tenant, name: "MyItem"))
    other = create(:tenant)
    create(:order, tenant: other, product: create(:product, tenant: other, name: "TheirItem"))
    sign_in owner

    get orders_path

    expect(response.body).to include("MyItem")
    expect(response.body).not_to include("TheirItem")
  end

  it "marks a paid order shipped" do
    order = create(:order, tenant: tenant, product: create(:product, tenant: tenant, stock: 5), aasm_state: "paid")
    sign_in owner

    patch ship_order_path(order)

    expect(order.reload).to be_shipped
  end
end
