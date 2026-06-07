require "rails_helper"

RSpec.describe "API v1 auth", type: :request do
  let(:password) { "password123" }
  let(:user) { create(:user, password: password) }

  def login
    post "/api/v1/login", params: { email: user.email, password: password }
    JSON.parse(response.body)
  end

  def refresh(token)
    post "/api/v1/refresh", params: { refresh_token: token }
  end

  it "returns access + refresh tokens for valid credentials" do
    body = login
    expect(response).to have_http_status(:ok)
    expect(body).to include("access_token", "refresh_token")
  end

  it "rejects bad credentials" do
    post "/api/v1/login", params: { email: user.email, password: "wrong" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "rotates: a refresh token returns a new pair and is single-use" do
    old = login["refresh_token"]

    refresh(old)
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to include("access_token", "refresh_token")

    refresh(old) # replay the spent token
    expect(response).to have_http_status(:unauthorized)
  end

  it "detects reuse: replaying a rotated token revokes the whole family" do
    old = login["refresh_token"]
    refresh(old)
    fresh = JSON.parse(response.body)["refresh_token"]

    refresh(old) # theft signal
    expect(response).to have_http_status(:unauthorized)

    refresh(fresh) # the newly-issued one is killed too
    expect(response).to have_http_status(:unauthorized)
  end

  it "logout revokes the refresh token" do
    token = login["refresh_token"]

    delete "/api/v1/logout", params: { refresh_token: token }
    expect(response).to have_http_status(:no_content)

    refresh(token)
    expect(response).to have_http_status(:unauthorized)
  end
end
