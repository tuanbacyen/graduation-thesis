class Api::UsersController < Api::BaseController
  # skip_before_action :authenticate_request!, only: :create
  before_action :authenticate_request!, only: [:index, :create_account, :show]
  before_action :check_admin?, only: [:index, :create_account]

  def index
    users = User.api_load_users
    render_json "get user succsess", users
  end

  def show
    render_json "Lấy dữ liệu thành công", current_user.load_attribute_user
  end

  def create_account
    user = User.new user_params false
    user.password = user.default_password
    if user.save
      user.images.create!(image: params[:user][:avatar])
      render_json "create success", User.find(user.id).load_structure
    else
      render_json user.errors.messages, nil, 1
    end
  end

  def create
    user = User.new user_params true
    user.password_confirmation = user.password
    user.role = "ctv"
    user.gender = true
    user.adress = ""
    user.birth = "1980/01/01"

    if user.save
      if params[:user][:avatar]
        image = user.images.build
        image.image = params[:user][:avatar]
        image.save
      end
      render_json "Tạo tài khoản thành công", user.load_attribute_user
    else
      render_json user.errors.messages, nil, 1
    end
  end

  def forgot_password
    user = User.find_by email: params[:email]
    if user.nil?
      render_json nil, "Email không tồn tại trong hệ thống. vui lòng kiểm tra lại!", 1
    else
      ForgotPasswordMailer.forgot_email(user).deliver_now if user.check_otp_forgot.blank?
      render_json nil, "Thành công, vui lòng kiểm tra email", 0
    end
  end

  def change_pass
    user = User.find_by email: params[:email]
    otp = params[:otp]
    new_pass = params[:newpass]
    if user.nil?
      render_json "Email không tồn tại", nil, 1
    else
      otps = user.check_otp otp
      unless otps.blank?
        user.update_attributes(password: new_pass, password_confirmation: new_pass)
        otps.destroy_all
        render_json "Đổi mật khẩu thành công", nil
      end
    end
  end

  private
  def user_params signup
    if signup
      params.require(:user).permit :email, :phone, :name, :password
    else
      params.require(:user).permit :email, :phone, :name, :gender, :adress, :birth, :role
    end
  end
end
