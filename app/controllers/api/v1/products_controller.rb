module Api
  module V1
    class ProductsController < BaseController
      # acts_as_tenant scopes both of these to the current user's store
      def index
        render json: Product.order(:name).as_json(only: %i[id name price_cents stock])
      end

      def show
        product = Product.find(params[:id])
        render json: product.as_json(only: %i[id name price_cents stock])
      end
    end
  end
end
