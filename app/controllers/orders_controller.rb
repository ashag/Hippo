class OrdersController < ApplicationController
  before_action :set_order, except: [:new, :create, :show] #don't want to show only current order
  before_action :set_products, only: [:add_product, :update_quantity, :checkout]
  before_action :check_order, only: [:add_product]
  before_action :totals, only: [:update_quantity, :checkout]

  def new
    @order = Order.new
  end

  def create
  end

  def edit
  end

  def update
  end

  def show
    @order = Order.find(params[:id])
    @orderproduct = OrderProduct.new 
    @products = @order.products
    puts "PRODUCTS = #{@products}"
    unless @products == nil?
      totals
    end
  end
  
  def add_product
    if check_order
      flash[:notice] = "You already have this product in your cart!"
      redirect_to order_path(current_order)
    else 
    @product = Product.find(params[:product_id])
    @orderproduct = OrderProduct.new(
      order_id: current_order.id, 
      product_id: params[:product_id], 
      quantity: params[:quantity])
      if @orderproduct.save
        redirect_to order_path(current_order) #changes url
      else 
        flash.now[:notice] = "There was a problem adding this item to the cart." #render doesn't show notice b/c generates page first
        render :show
      end
    end
  end

  def remove_product
    @orderproduct = OrderProduct.find_by(order_id: current_order.id, product_id: params[:product_id])
    @orderproduct.destroy
    redirect_to order_path(current_order) #why doesn't need to be current_order.id?
  end

  def update_quantity
    @orderproduct = OrderProduct.find_by(order_id: current_order.id, product_id: params[:product_id])
    if @orderproduct.update(quantity:params[:quantity])
      redirect_to order_path(current_order)
    else
      flash.now[:notice] = "There was problem updating your order."
      render :show
    end
  end

  def checkout
  end

  def submit
   current_order.update(status:params[:payment_method])
   current_order.products.each do |product|
     product.update(inventory:product.inventory - OrderProduct.find_by(product_id:product.id, order_id:current_order.id).quantity)
   end
  end

private
  def check_user
    @order = Order.find(params[:id])
    @order.user_id == session[:user_id]
  end

  def check_order
   @product = Product.find(params[:product_id])
   OrderProduct.find_by(product_id: @product.id, order_id: current_order.id).present?
  end
  
  def set_order
    @order = current_order 
  end

  def set_products
    @products = current_order.products
  end

  def totals
    @items = current_order.order_products.map {|x| x.quantity} 
    @item_total =  @items.inject(:+)
    @subtotals = @products.map do |product|
      product.price * OrderProduct.find_by(product_id: product.id, order_id: @order.id).quantity
    end
    @total = @subtotals.reduce(:+)
  end

  helper_method :check_user

end


