class ProductsController < ApplicationController
  before_action :product_new, only:[:new]
  before_action :product_info, only: [:show, :item_show, :destroy, :edit, :update]
  before_action :move_to_login,only:[:new, :destroy]
  before_action -> {seller_check(:back)}, only: [:edit]
  before_action -> {seller_check(root_path)}, only: [:update, :item_show]
  skip_before_action :authenticate_user!, only: [:show, :item_show, :search, :price_recommend, :price_recommend_result]

  def show
    @images = @product.images
    @product_price = @product.price.to_s(:delimited)
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
    @comment = Comment.new
    @comments = @product.comments.includes(:user)
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
    @images = @product.images
    gon.images = @images.length
    @product_price = @product.price.to_s(:delimited)
    @comment = Comment.new
    @comments = @product.comments.includes(:user)
  end

# 商品出品
  def new
    @product.images.build
    @parents        = Category.where(belongs:"parent")
    gon.children    = Category.where(belongs:"child")
    gon.g_children  = Category.where(belongs:"g_child")
    @sizes          = Size.all
    @prefectures    = JpPrefecture::Prefecture.all
  end

  def create
    @product = Product.new(product_params)
    if @product.brand
      @product.brand = Brand.find_or_create_by(name: @product.brand.name)
    end
    if params[:image]
      if @product.save
        params[:image].each do |i|
          @product.images.create(product_id: @product.id, image: i)
        end
        redirect_to root_path
      else
        @product.images.build
        render action: :new
      end
    else
      flash.now[:alert] = "画像を設定してください"
      render action: :new
    end
  end

# 商品編集
  def edit
    flash.now[:alert] = "画像は再度設定をしてください"
    gon.images = @product.images
    gon.category = @product.category.id
    if @product.category.parent.present?
      gon.category_parent = @product.category.parent.id
      if @product.category.parent.parent.present?
        gon.category_g_parent = @product.category.parent.parent.id
      end
    end

    @parents        = Category.where(belongs:"parent")
    @children       = Category.where(ancestry: "#{@product.category.parent.parent.id}")
    @child          = @product.category.parent
    @g_children     = @child.children
    gon.children    = Category.where(belongs:"child")
    gon.g_children  = Category.where(belongs:"g_child")
    @sizes = Size.all
    @prefectures = JpPrefecture::Prefecture.all
    @product.brand if @product.brand == nil
  end

  def update
    if params[:image]
      if params[:product][:brand_attributes]
        @brand = Brand.find_or_create_by(brand_params)
        @product.brand_id = @brand.id
      end
      if @product.update(product_params_update)
        @product.images = []
        params[:image].each do |i|
          @product.images.create(product_id: @product.id, image: i)
        end
        redirect_to "/items/#{@product.id}"
      else
        redirect_back(fallback_location: edit_product_path)
      end
    else
      flash.now[:alert] = "画像を設定してください"
      redirect_back(fallback_location: edit_product_path)
    end
  end

  def search
    gon.search_params = gon_search_params

    @search_data    = Product.ransack(search_params)
    @keyword        = search_params[:info_or_name_or_brand_name_or_category_name_cont_all]
    @products       = Product.order(id: :DESC).includes(:images)
    @product_result = @search_data.result(distinct: true)
    @product_count  = @product_result.length

    @parents        = Category.where(belongs:"parent")
    gon.children    = Category.where(belongs:"child")
    gon.g_children  = Category.where(belongs:"g_child")

    @size_groups = SizeGroup.all
    gon.sizes = Size.all

  end

  def transaction
    @product = Product.find(params[:id])
    if @product.buyer_id != nil
      redirect_to product_path(@product)
    end
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
      @product.update!(buyer_id: current_user.id,sell_status_id: 2)
    end
  end

  #ユーザー出品商品一覧
  def listing
    @products = Product.where(seller_id: current_user.id, buyer_id: nil)
  end

  def in_progress
    @products = Product.where(seller_id: current_user.id).where.not(buyer_id: nil)
  end

  def completed
    @products = Product.where(seller_id: current_user.id).where.not(buyer_id: nil)
  end

  #ユーザー購入済み商品一覧
  def purchased
    @product = Product.where(buyer_id: current_user.id, sell_status_id: 2)
  end

  # 商品価格査定
  def price_recommend
    @product = PriceRecommend.new
    @category_parent = Category.where(belongs:"parent")
    gon.children    = Category.where(belongs:"child")
    gon.g_children  = Category.where(belongs:"g_child")
  end

  def price_recommend_result
    @product = PriceRecommend.new(recommend_params)
    @same_product = Product.search(recommend_params)
    @same_product_price = @same_product.average(:price).floor.to_s(:delimited) if @same_product.present?
  end

  private
  def brand_params
    params.require(:product).require(:brand_attributes).permit(:name)
  end

  def product_new
    @product = Product.new
  end

  def image_params
    params.permit(:image)
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
      :brand_id,
      images_attributes: [:id,:product_id,:image,:_destroy],
      brand_attributes: [:id,:name]
    ).merge(seller_id: current_user.id,sell_status_id: 1)
  end

  def product_params_update
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
      images_attributes: [:id,:product_id,:image,:_destroy],
    ).merge(seller_id: current_user.id,sell_status_id: 1)
  end

  def product_info
    @product = Product.find(params[:id])
  end

  def search_params
    if params[:q][:category_id_in].blank?
      if params[:q][:category_id_eq].present?
        categories = Category.where("ancestry LIKE ?", "%/#{params[:q][:category_id_eq]}")
        category_ids = categories.map(&:id)
      else
        categories = Category.where("ancestry LIKE ?", "#{params[:q][:category_id]}/%")
        category_ids = categories.map(&:id)
      end
      params[:q][:category_id_in] = category_ids
    end

    params.require(:q).permit(
      :s,
      :info_or_name_or_brand_name_or_category_name_cont_all,
      {:category_id_in => []},
      :brand_name_cont_all,
      {:size_id_in => []},
      :price_gteq,
      :price_lteq,
      {:status_eq_any => []},
      {:delivery_fee_owner_eq_any => []},
      :buyer_id_null,
      :buyer_id_not_null
      ) unless params[:q].blank?
  end

  def gon_search_params
    params.require(:q).permit(
      :category_id,
      :category_id_eq,
      {:category_id_in => []},
      :size_size_group_id,
      {:size_id_in => []},
      :s)
  end

  def recommend_params
    params.require(:price_recommend).permit(
      :category_id,
      :brand_id,
      :status)
  end

  def move_to_login
    redirect_to new_user_session_path unless user_signed_in?
  end

  def seller_check(a_path)
    unless current_user.id == @product.seller_id
      redirect_to a_path
    end
  end

end
