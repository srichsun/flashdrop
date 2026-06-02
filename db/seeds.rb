# Demo data. Idempotent: safe to run repeatedly (find_or_create_by everywhere).
# Two separate stores so the multi-tenant isolation is visible after login.
#
# Logins (password "password123"):
#   owner@example.com  / staff@example.com   -> Demo Store
#   owner2@example.com                        -> Coffee Lab

SEED_IMAGES = Dir[Rails.root.join("db/seeds/images/*.jpg")].sort unless defined?(SEED_IMAGES)

# Attach a demo photo (round-robin through the bundled images). Wrapped in a
# rescue so a missing/misconfigured object store never breaks the boot-time seed.
def attach_demo_image(product, index)
  return if product.image.attached? || SEED_IMAGES.empty?

  path = SEED_IMAGES[index % SEED_IMAGES.size]
  product.image.attach(io: File.open(path), filename: File.basename(path), content_type: "image/jpeg")
rescue => e
  warn "Skipped image for #{product.name}: #{e.message}"
end

def seed_store(name:, owner_email:, staff_email: nil, products:)
  store = Tenant.find_or_create_by!(name: name)

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

  products.each_with_index do |attrs, i|
    product = store.products.find_or_create_by!(name: attrs[:name]) do |p|
      p.price_cents = attrs[:price_cents]
      p.stock = attrs[:stock]
    end
    attach_demo_image(product, i)
  end

  store
end

demo = seed_store(
  name: "Demo Store",
  owner_email: "owner@example.com",
  staff_email: "staff@example.com",
  products: [
    { name: "Cold Brew Coffee",   price_cents: 12_000, stock: 50 },
    { name: "Ceramic Mug",        price_cents: 38_000, stock: 20 },
    { name: "Pour-over Dripper",  price_cents: 45_000, stock: 15 },
    { name: "Paper Filters ×100", price_cents: 18_000, stock: 80 },
    { name: "Stainless Tumbler",  price_cents: 52_000, stock: 12 },
    { name: "Coffee Beans 250g",  price_cents: 36_000, stock: 40 },
    { name: "Gift Box Set",       price_cents: 88_000, stock: 8 },
    { name: "Tote Bag",           price_cents: 25_000, stock: 0 } # sold out
  ]
)

seed_store(
  name: "Coffee Lab",
  owner_email: "owner2@example.com",
  products: [
    { name: "Espresso Beans 1kg", price_cents: 60_000, stock: 30 },
    { name: "Pour-over Kettle",   price_cents: 95_000, stock: 8 },
    { name: "Milk Frother",       price_cents: 42_000, stock: 18 }
  ]
)

# A spread of orders for the Demo Store so the dashboard and the paginated
# orders page have something to show.
if demo.orders.none?
  products = demo.products.to_a
  emails = %w[alice bob carol dave erin frank grace heidi ivan judy].map { |n| "#{n}@example.com" }

  28.times do
    Order.create!(
      tenant: demo,
      product: products.sample,
      quantity: rand(1..3),
      customer_email: emails.sample,
      aasm_state: %w[paid paid paid shipped shipped pending].sample,
      created_at: rand(0..21).days.ago
    )
  end
end

puts "Seeded #{Tenant.count} stores, #{User.count} users, " \
     "#{Product.count} products, #{Order.count} orders."
