require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "redirects to login when logged out" do
    get root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "shows the store name when logged in" do
    user = create(:user, tenant: create(:tenant, name: "Acme"))
    sign_in user

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Acme")
  end

  it "lists recent paid orders" do
    user = create(:user)
    product = create(:product, tenant: user.tenant, name: "Live Mug", stock: 5)
    create(:order, tenant: user.tenant, product: product, aasm_state: "paid")
    sign_in user

    get root_path

    expect(response.body).to include("Live Mug")
  end
end
