class Order < ApplicationRecord
  include AASM

  acts_as_tenant :tenant
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0, only_integer: true }

  before_validation :set_total, on: :create

  # Fire the post-payment chain on the real DB commit (Rails-native, production-safe)
  after_update_commit :enqueue_post_payment, if: :just_became_paid?

  # Order lifecycle. AASM wraps each transition (and its callbacks) in a DB
  # transaction, so if decrementing stock fails the whole "pay" rolls back.
  aasm do
    state :pending, initial: true
    state :paid, :shipped, :cancelled

    event :pay do
      # Take the stock now; raises InsufficientStock if there isn't enough,
      # which aborts the transition and leaves the order pending.
      transitions from: :pending, to: :paid, after: :decrement_stock
    end

    event :ship do
      transitions from: :paid, to: :shipped
    end

    event :cancel do
      transitions from: :pending, to: :cancelled
    end
  end

  private

  def set_total
    self.total_cents = product.price_cents * quantity if product && quantity
  end

  def decrement_stock
    product.sell!(quantity)
  end

  def just_became_paid?
    saved_change_to_aasm_state? && paid?
  end

  # Kick off the background chain once payment is committed (not inside the
  # transaction, so the job always sees the persisted paid order).
  def enqueue_post_payment
    NotifyStoreJob.perform_later(self)
    # Push the new sale onto the store's dashboard in real time (ActionCable)
    broadcast_prepend_to(tenant, target: "orders", partial: "orders/order", locals: { order: self })
  end
end
