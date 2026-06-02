require "rails_helper"

RSpec.describe "API v1 products", type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:auth) { { "Authorization" => "Bearer #{JsonWebToken.encode({ user_id: user.id })}" } }

  it "requires a valid token" do
    get "/api/v1/products"
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns only the authenticated user's store products" do
    create(:product, tenant: tenant, name: "Mine")
    create(:product, tenant: create(:tenant), name: "Theirs")

    get "/api/v1/products", headers: auth

    expect(response).to have_http_status(:ok)
    names = JSON.parse(response.body).map { |p| p["name"] }
    expect(names).to include("Mine")
    expect(names).not_to include("Theirs")
  end
end
