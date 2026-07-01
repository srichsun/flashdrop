class AddFlashSaleFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :original_price_cents, :integer
    add_column :products, :sale_starts_at, :datetime
    add_column :products, :sale_ends_at, :datetime
  end
end
