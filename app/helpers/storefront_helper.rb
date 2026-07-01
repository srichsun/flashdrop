module StorefrontHelper
  # Free Unsplash product photos (Unsplash License — free, no attribution) used as
  # demo placeholders when a product has no uploaded image. Picked deterministically
  # by product id so each product keeps the same photo.
  DEMO_IMAGE_IDS = %w[
    photo-1523275335684-37898b6baf30
    photo-1542291026-7eec264c27ff
    photo-1505740420928-5e560c06d30e
    photo-1526170375885-4d8ecf77b99f
    photo-1560769629-975ec94e6a86
    photo-1572635196237-14b3f281503f
    photo-1546868871-7041f2a55e12
    photo-1491553895911-0055eca6402d
    photo-1600185365483-26d7a4cc7519
    photo-1503602642458-232111445657
  ].freeze

  def demo_product_image(product, width:, height:)
    photo_id = DEMO_IMAGE_IDS[product.id % DEMO_IMAGE_IDS.size]
    "https://images.unsplash.com/#{photo_id}?w=#{width}&h=#{height}&fit=crop&auto=format"
  end
end
