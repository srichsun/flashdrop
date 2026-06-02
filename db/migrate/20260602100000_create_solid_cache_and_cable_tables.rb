class CreateSolidCacheAndCableTables < ActiveRecord::Migration[8.1]
  # Solid Cache and Solid Cable share the single production database with the
  # primary connection. db:prepare only loads the primary schema for an existing
  # database, so these tables (defined in db/cache_schema.rb / db/cable_schema.rb)
  # were never created. Create them here so they live in the shared database.
  def change
    create_table :solid_cache_entries, if_not_exists: true do |t|
      t.binary :key, limit: 1024, null: false
      t.binary :value, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer :key_hash, limit: 8, null: false
      t.integer :byte_size, limit: 4, null: false
      t.index [ :byte_size ], name: "index_solid_cache_entries_on_byte_size"
      t.index [ :key_hash, :byte_size ], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
      t.index [ :key_hash ], name: "index_solid_cache_entries_on_key_hash", unique: true
    end

    create_table :solid_cable_messages, if_not_exists: true do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer :channel_hash, limit: 8, null: false
      t.index [ :channel ], name: "index_solid_cable_messages_on_channel"
      t.index [ :channel_hash ], name: "index_solid_cable_messages_on_channel_hash"
      t.index [ :created_at ], name: "index_solid_cable_messages_on_created_at"
    end
  end
end
