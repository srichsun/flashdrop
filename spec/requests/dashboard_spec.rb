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
end
