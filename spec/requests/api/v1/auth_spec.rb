require "rails_helper"

RSpec.describe "API v1 auth", type: :request do
  it "returns a token for valid credentials" do
    user = create(:user, password: "password123")

    post "/api/v1/login", params: { email: user.email, password: "password123" }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to have_key("token")
  end

  it "rejects bad credentials" do
    user = create(:user, password: "password123")

    post "/api/v1/login", params: { email: user.email, password: "wrong" }

    expect(response).to have_http_status(:unauthorized)
  end
end
