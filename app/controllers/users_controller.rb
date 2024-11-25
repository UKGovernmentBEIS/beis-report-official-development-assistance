class UsersController < BaseController
  add_breadcrumb I18n.t("breadcrumb.users.index"), :users_path

  def index
    authorize :user, :index?
    @user_state = params[:user_state]
    @users = policy_scope(User).includes(:organisation).joins(:organisation).order("organisations.name ASC, users.name ASC")
    @users = if @user_state == "active"
      @users.active
    else
      @users.inactive
    end
  end

  def show
    @user = User.find(id)
    authorize @user

    add_breadcrumb t("breadcrumb.users.show"), user_path(@user)
  end

  def new
    @user = User.new
    authorize @user
    @service_owner = service_owner
    @partner_organisations = partner_organisations

    add_breadcrumb t("breadcrumb.users.new"), new_user_path
  end

  def create
    @user = User.new(user_params)
    authorize @user
    @service_owner = service_owner
    @partner_organisations = partner_organisations

    result = CreateUser.new(user: @user, organisation: organisation).call
    if result.success?
      flash.now[:notice] = t("action.user.create.success")
      redirect_to user_path(@user.reload.id)
    else
      flash.now[:error] = t("action.user.create.failed", error: result.error_message)
      render :new
    end
  end

  def edit
    @user = User.find(id)
    authorize @user
    @service_owner = service_owner
    @partner_organisations = partner_organisations

    add_breadcrumb t("breadcrumb.users.edit"), edit_user_path(@user)
  end

  def update
    @user = User.find(id)
    authorize @user
    @service_owner = service_owner
    @partner_organisations = partner_organisations

    reset_mfa = user_params.delete(:reset_mfa)
    @user.assign_attributes(user_params.except(:reset_mfa))

    if @user.valid?
      result = UpdateUser.new(user: @user, organisation: organisation, reset_mfa: reset_mfa).call

      if result.success?
        flash[:notice] = t("action.user.update.success")
        redirect_to user_path(@user)
      else
        flash.now[:error] = t("action.user.update.failed")
        render :edit
      end
    else
      render :edit
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :organisation_id, :active, :reset_mfa)
  end

  def id
    params[:id]
  end

  def organisation_id
    user_params[:organisation_id]
  end

  def organisation
    Organisation.find_by(id: organisation_id)
  end

  private def service_owner
    Organisation.service_owner
  end

  private def partner_organisations
    Organisation.partner_organisations
  end
end
