class Staff::UsersController < Staff::BaseController
  def index
    @users = policy_scope(User)
    authorize @users
  end

  def show
    @user = policy_scope(User).find(id)
    authorize @user
  end

  def new
    @user = policy_scope(User).new
    @organisations = policy_scope(Organisation)
    authorize @user
  end

  def create
    @user = policy_scope(User).new(user_params)
    @organisations = policy_scope(Organisation)
    authorize @user

    if @user.valid?
      result = CreateUser.new(user: @user, organisations: organisations).call
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

  def edit
    @user = policy_scope(User).find(id)
    @organisations = policy_scope(Organisation)
    authorize @user
  end

  def update
    @user = policy_scope(User).find(id)
    @organisations = policy_scope(Organisation)
    authorize @user

    @user.assign_attributes(user_params)

    if @user.valid?
      result = UpdateUser.new(user: @user, organisations: organisations).call

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
    params.require(:user).permit(:name, :email, organisation_ids: [])
  end

  def id
    params[:id]
  end

  def organisation_ids
    user_params[:organisation_ids]
  end

  def organisations
    Organisation.where(id: organisation_ids)
  end
end
