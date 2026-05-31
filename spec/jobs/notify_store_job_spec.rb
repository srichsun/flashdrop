require "rails_helper"

RSpec.describe NotifyStoreJob, type: :job do
  it "emails the store owner and queues fulfillment" do
    owner = create(:user, role: :owner)
    order = create(:order, tenant: owner.tenant,
                           product: create(:product, tenant: owner.tenant, stock: 5))

    expect { NotifyStoreJob.perform_now(order) }
      .to change { ActionMailer::Base.deliveries.size }.by(1)
      .and have_enqueued_job(FulfillmentJob).with(order)
  end
end
