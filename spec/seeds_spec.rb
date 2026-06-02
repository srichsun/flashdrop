require "rails_helper"

# Truncation so we seed against a clean database and real commits happen.
RSpec.describe "db/seeds", :no_transaction do
  it "creates demo data and is idempotent" do
    expect { Rails.application.load_seed }.to change(Tenant, :count).by(2)

    expect(User.find_by(email: "owner@example.com")).to be_present
    expect(Tenant.find_by(name: "Demo Store").products.count).to be >= 5

    # running it again doesn't duplicate anything
    expect { Rails.application.load_seed }.not_to change(Tenant, :count)
  end
end
