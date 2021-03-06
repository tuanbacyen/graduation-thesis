class SellsController < ApplicationController
  before_action :check_admin
  before_action :authenticate_user!
  before_action :get_sell, only: :show

  def index
    params[:from_date] = convert_date params[:from_date] if params[:from_date].present?
    params[:to_date] = convert_date params[:to_date] if params[:to_date].present?
    @q = Sell.ransack(params[:q])
    @sells = current_user.sells.from_date(params[:from_date]).to_date(params[:to_date]).order(created_at: :desc).ransack(params[:q]).result.page(params[:page]).per(10)
  end

  def show
    @list_items = @sell.details.hash_product_details
  end

  def new
    @sell = Sell.new
    @products = Product.get_by_ids(current_user.warehouse.product_ids)
    @pws = current_user.warehouse.product_warehouses
  end

  def create
    sell = current_user.sells.build sell_params
    sell.sell_code = "BH-#{sell.user.id}-#{Time.current.to_i}"
    sell.total_count = 0
    sell.total_price = 0

    if sell.save
      details sell
      SellBillMailer.sell_bill(sell, params[:email]).deliver_now unless params[:email].blank?
      flash[:success] = "Bán hàng thành công"
      redirect_to sells_path
    else
      flash[:danger] = "Thất bại"
      render :new
    end
  end

  private
  def sell_params
    params.require(:sell).permit :description
  end

  def details sell
    pws_all = current_user.warehouse.product_warehouses
    pw_ids = params[:bill_pw]
    counts = params[:bill_count]
    prices = params[:bill_price].map{|e| convert_price e}
    pw_ids.each_with_index do |p_id, i|
      pws = pws_all.can_sell(p_id)
      count = counts[i].to_i

      next if count > pws.sum(:count)

      index = 0
      while count.positive?
        count_temp = pws[index].count <= count ? pws[index].count : count
        sell.details.build(product_warehouse_id: pws[index].id, count: count_temp, price: prices[i]).save
        index += 1
        count -= count_temp
      end
    end
    sell.update_product_in_warehouse
    sell.auto_update_attribute
  end

  def get_sell
    @sell = Sell.find_by id: params[:id]

    return if @sell&.of_user(current_user.id)
    flash[:danger] = "sell not found"
    redirect_to sells_path
  end
end
