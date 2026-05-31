require "rails_helper"

RSpec.describe Order, type: :model do
  it "is valid with the factory and starts pending" do
    order = create(:order)
    expect(order).to be_valid
    expect(order).to be_pending
  end

  it "snapshots the total from the product price" do
    product = create(:product, price_cents: 250)
    order = create(:order, product: product, tenant: product.tenant, quantity: 3)
    expect(order.total_cents).to eq(750)
  end

  describe "#pay!" do
    it "moves to paid and decrements stock" do
      product = create(:product, stock: 5)
      order = create(:order, product: product, tenant: product.tenant, quantity: 2)

      order.pay!

      expect(order).to be_paid
      expect(product.reload.stock).to eq(3)
    end

    it "rolls back and stays pending when stock is too low" do
      product = create(:product, stock: 1)
      order = create(:order, product: product, tenant: product.tenant, quantity: 2)

      expect { order.pay! }.to raise_error(Product::InsufficientStock)

      expect(order.reload).to be_pending
      expect(product.reload.stock).to eq(1)
    end

    it "won't pay an already-paid order (no double charge)" do
      order = create(:order, product: create(:product, stock: 5))
      order.pay!
      expect(order.may_pay?).to be(false)
    end

    # :no_transaction so the after_commit callback actually fires
    it "kicks off the post-payment job chain once committed", :no_transaction do
      order = create(:order, product: create(:product, stock: 5))
      expect { order.pay! }.to have_enqueued_job(NotifyStoreJob).with(order)
    end
  end

  describe "#ship!" do
    it "ships a paid order" do
      order = create(:order, product: create(:product, stock: 5))
      order.pay!
      order.ship!
      expect(order).to be_shipped
    end

    it "can't ship a pending order" do
      order = create(:order)
      expect(order.may_ship?).to be(false)
    end
  end

  describe "#cancel!" do
    it "cancels a pending order" do
      order = create(:order)
      order.cancel!
      expect(order).to be_cancelled
    end
  end
end
