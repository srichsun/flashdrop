class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  # Concurrent index creation can't run inside a transaction
  disable_ddl_transaction!

  def change
    # Speed up pg_search trigram search on product names (seq scan -> index scan)
    add_index :products, :name, using: :gin, opclass: :gin_trgm_ops,
              name: "index_products_on_name_trigram",
              algorithm: :concurrently, if_not_exists: true

    # The ECPay webhook looks orders up by this
    add_index :orders, :payment_ref, algorithm: :concurrently, if_not_exists: true

    # Dashboard / orders list: scoped to a store, ordered by recency
    add_index :orders, [ :tenant_id, :created_at ], algorithm: :concurrently, if_not_exists: true
  end
end
