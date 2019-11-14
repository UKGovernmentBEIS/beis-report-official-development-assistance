class Staff::UsersController < Staff::BaseController
  def index
    @users = User.all
  end

  def show
    @user = User.find(id)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.valid?
      @user.save
      flash[:notice] = I18n.t("form.user.create.success")
      redirect_to users_path(@user)
    else
      render :new
    end
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end

  def id
    params[:id]
  end
end
