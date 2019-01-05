class ProductsController < ApplicationController
  before_action :product_new, only:[:new]
  before_action :product_info, only: [:show, :item_show, :destroy]

  def new
   @product.images.build
  end

  def create
    @product = Product.new(product_params)
    @product.brand = Brand.find_or_create_by(name: @product.brand.name) if @product.brand.name

    respond_to do |format|
      if @product.save
        params[:images][:image].each do |i|
          @product.images.create(product_id: @product.id, image: i)
        end
        format.html { redirect_to root_path}
        # redirect_to root_path
      else
        render action: :new
      end
    end
  end

  def show
    @images = @product.images
    gon.images = @images.length
    @sell_user = @product.seller
    @sell_other_products = Product.where(seller_id: @product.seller_id)
    @sell_product_brand = @product.brand
    @sell_product_category = @product.category

    if @product.brand_id.present? && @product.category_id.present?
      @related_items = Product.where(brand_id: @product.brand_id, category_id: @product.category_id).where.not(id: @product.id)
    else @product.brand_id.present? || @product.category_id.present?
      @related_items = Product.where("brand_id = ? or category_id = ?", @product.brand_id, @product.category_id)
    end
  end

  def destroy
    if current_user.id == @product.seller_id
      if @product.destroy
        redirect_to root_path
      else
        render :show
      end
    end
  end

  def item_show
    @image = @product.images[0]
  end



  def transaction
    @product = Product.find(params[:format])
  end

  private
  def product_new
    @product = Product.new
  end


  def completed_transaction
    ActiveRecord::Base.transaction do

      @product = Product.find(params[:id])
      require 'payjp'
      Payjp.api_key = PAYJP_SECRET_KEY

      Payjp::Charge.create(
        amount:  @product.price,
        card:    params['payjp-token'],
        currency: 'jpy',
      )
      @product.update!(buyer_id: current_user.id)
    end
  end


  def product_params
    params.require(:product).permit(
      :name,
      :info,
      :price,
      :category_id,
      :size_id,
      :status,
      :delivery_fee_owner,
      :shipping_method,
      :delivery_date,
      :prefecture,
      images_attributes: [:id,:product_id, {image: []}],
      brand_attributes: [:name]
    ).merge(seller_id: current_user.id,sell_status_id: 1)
  end

  def product_info
    @product = Product.find(params[:id])
  end
end
