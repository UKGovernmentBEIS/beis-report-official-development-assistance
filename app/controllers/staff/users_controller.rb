class Staff::UsersController < Staff::BaseController
  def index
    authorize :user, :index?
    @users = policy_scope(User)
  end

  def show
    @user = User.find(id)
    authorize @user
  end

  def new
    @user = User.new
    authorize @user
    @organisations = policy_scope(Organisation)
  end

  def create
    @user = User.new(user_params)
    authorize @user
    @organisations = policy_scope(Organisation)

    if @user.valid?
      result = CreateUser.new(user: @user, organisation: organisation).call
      if result.success?
        flash.now[:notice] = I18n.t("form.user.create.success")
        redirect_to user_path(@user.reload.id)
      else
        flash.now[:error] = I18n.t("form.user.create.failed")
        render :new
      end
    else
      render :new
    end
  end

  def edit
    @user = User.find(id)
    authorize @user
    @organisations = policy_scope(Organisation)
  end

  def update
    @user = User.find(id)
    authorize @user
    @organisations = policy_scope(Organisation)

    @user.assign_attributes(user_params)

    if @user.valid?
      result = UpdateUser.new(user: @user, organisation: organisation).call

      if result.success?
        flash.now[:notice] = I18n.t("form.user.update.success")
        redirect_to user_path(@user)
      else
        flash.now[:error] = I18n.t("form.user.update.failed")
        render :edit
      end
    else
      render :edit
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :organisation_id)
  end

  def id
    params[:id]
  end

  def organisation_id
    user_params[:organisation_id]
  end

  def organisation
    Organisation.find(organisation_id)
  end
end
