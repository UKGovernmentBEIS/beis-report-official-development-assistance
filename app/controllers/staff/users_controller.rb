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
      result = CreateUser.new(user: @user).call
      if result.success?
        flash.now[:notice] = I18n.t("form.user.create.success")
        return redirect_to user_path(@user.reload.id)
      else
        flash.now[:error] = I18n.t("form.user.create.failed")
        render :new
      end
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
