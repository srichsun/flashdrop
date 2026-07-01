# Demo data. Idempotent: safe to run repeatedly (find_or_create_by everywhere).
# Two separate stores so the multi-tenant isolation is visible after login.
#
# Logins (password "password123"):
#   owner@example.com  / staff@example.com   -> How to Beast (@howtobeast)
#   owner2@example.com                        -> Wisdm (@wisdm)

# Attach the product's demo photo (db/seeds/images/<filename>). Wrapped in a
# rescue so a missing/misconfigured object store never breaks the boot-time seed.
def attach_demo_image(product, filename)
  return if filename.blank?

  path = Rails.root.join("db/seeds/images", filename)
  return unless File.exist?(path)

  unless product.image.attached? && product.image.blob.filename.to_s == filename && demo_image_present?(product)
    product.image.purge if product.image.attached?
    product.image.attach(io: File.open(path), filename: filename, content_type: "image/jpeg")
  end

  # Pre-generate the :card thumbnail so the storefront serves a ready-made
  # variant instead of processing it on the first request (visible lag).
  # Best effort: skip where libvips isn't installed (e.g. CI) — LoadError isn't
  # a StandardError, so catch it explicitly; the variant is made on demand there.
  begin
    product.image.variant(:card).processed
  rescue StandardError, LoadError => e
    warn "Skipped thumbnail pre-gen for #{product.name}: #{e.message}"
  end
rescue => e
  warn "Skipped image for #{product.name}: #{e.message}"
end

# True only if the attached original actually exists on the current service.
def demo_image_present?(product)
  blob = product.image.blob
  blob.service_name.to_s == ActiveStorage::Blob.service.name.to_s && blob.service.exist?(blob.key)
rescue StandardError
  false
end

def seed_store(name:, owner_email:, staff_email: nil, products:, instagram_handle: nil, verified: false)
  store = Tenant.find_or_create_by!(name: name) do |t|
    t.instagram_handle = instagram_handle
    t.verified = verified
  end

  User.find_or_create_by!(email: owner_email) do |u|
    u.tenant = store
    u.password = "password123"
    u.role = :owner
  end

  if staff_email
    User.find_or_create_by!(email: staff_email) do |u|
      u.tenant = store
      u.password = "password123"
      u.role = :staff
    end
  end

  # Scope creation to this store so acts_as_tenant sets tenant_id unambiguously.
  ActsAsTenant.with_tenant(store) do
    products.each do |attrs|
      product = Product.find_or_create_by!(name: attrs[:name]) do |p|
        p.price_cents = attrs[:price_cents]
        p.stock = attrs[:stock]
        p.original_price_cents = attrs[:original_price_cents]
        p.sale_starts_at = attrs[:sale_starts_at]
        p.sale_ends_at = attrs[:sale_ends_at]
      end
      attach_demo_image(product, attrs[:image])
    end
  end

  store
end

# One influencer's flash-sale shop: a handful of limited drops with a markdown
# off the original price and a live sale window. No local images — the storefront
# falls back to free Unsplash product photos.
demo = seed_store(
  name: "How to Beast",
  instagram_handle: "howtobeast",
  verified: true,
  owner_email: "owner@example.com",
  staff_email: "staff@example.com",
  products: [
    { name: "Oversized Hoodie",  price_cents: 5_900, original_price_cents: 9_900,  stock: 8,
      sale_starts_at: 1.hour.ago, sale_ends_at: 2.days.from_now },
    { name: "Canvas Tote Bag",   price_cents: 2_900, original_price_cents: 4_500,  stock: 15,
      sale_starts_at: 1.hour.ago, sale_ends_at: 1.day.from_now },
    { name: "Everyday Sneakers", price_cents: 8_900, original_price_cents: 14_900, stock: 5,
      sale_starts_at: 1.hour.ago, sale_ends_at: 3.days.from_now }
  ]
)

seed_store(
  name: "Wisdm",
  instagram_handle: "wisdm",
  verified: true,
  owner_email: "owner2@example.com",
  products: [
    { name: "Espresso Beans 1kg", price_cents: 60_000, stock: 30, image: "espresso-beans.jpg" },
    { name: "Pour-over Kettle",   price_cents: 95_000, stock: 8, image: "pour-over-kettle.jpg" },
    { name: "Milk Frother",       price_cents: 42_000, stock: 18, image: "milk-frother.jpg" }
  ]
)

# A spread of orders for the Demo Store so the dashboard and the paginated
# orders page have something to show.
ActsAsTenant.with_tenant(demo) do
  if demo.orders.none?
    products = demo.products.to_a
    emails = %w[alice bob carol dave erin frank grace heidi ivan judy].map { |n| "#{n}@example.com" }

    12.times do
      Order.create!(
        product: products.sample,
        quantity: rand(1..3),
        customer_email: emails.sample,
        aasm_state: %w[paid paid paid shipped shipped pending].sample,
        created_at: rand(0..21).days.ago
      )
    end
  end
end

puts "Seeded #{Tenant.count} stores, #{User.count} users, " \
     "#{Product.count} products, #{Order.count} orders."
