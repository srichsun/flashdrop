class CreateRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false   # SHA-256 of the raw token; never store the raw
      t.datetime :expires_at, null: false
      t.datetime :revoked_at                 # null = active
      t.string :user_agent                   # which device, for "log out this device"
      t.timestamps
    end
    add_index :refresh_tokens, :token_digest, unique: true
  end
end
