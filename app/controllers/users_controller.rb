class UsersController < BaseController
  add_breadcrumb I18n.t("breadcrumb.users.index"), :users_path

  def index
    authorize :user, :index?
    @user_state = params[:user_state]
    @users = if @user_state == "active"
      policy_scope(User).all_active
    else
      policy_scope(User).all_deactivated
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
    @user = User.new(user_params.except(:active, :additional_organisations))
    authorize @user
    @service_owner = service_owner
    @partner_organisations = partner_organisations

    result = CreateUser.new(user: @user, organisation:, additional_organisations:).call
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
    active = user_params.has_key?(:active) ? user_params[:active] == "true" : @user.active
    @user.assign_attributes(user_params.except(:reset_mfa, :active, :additional_organisations))
    @user.additional_organisations = additional_organisations

    if @user.valid?
      result = UpdateUser.new(user: @user, active:, organisation:, reset_mfa:, additional_organisations:).call

      if result.success?
        k = if user_params.has_key?(:active)
          active ? "_reactivated" : "_deactivated"
        end
        flash[:notice] = t("action.user.update.success#{k}")
        redirect_to user_path(@user)
      else
        flash.now[:error] = t("action.user.update.failed")
        render :edit
      end
    else
      render :edit
    end
  end

  def deactivate
    @user = User.find(id)
    authorize @user

    add_breadcrumb t("breadcrumb.users.edit"), edit_user_path(@user)
    add_breadcrumb t("breadcrumb.users.deactivate"), deactivate_user_path(@user)
  end

  def reactivate
    @user = User.find(id)
    authorize @user

    add_breadcrumb t("breadcrumb.users.edit"), edit_user_path(@user)
    add_breadcrumb t("breadcrumb.users.reactivate"), reactivate_user_path(@user)
  end

  def anonymise
    @user = User.find(id)
    authorize @user

    add_breadcrumb t("breadcrumb.users.edit"), edit_user_path(@user)
    add_breadcrumb t("breadcrumb.users.anonymise"), anonymise_user_path(@user)
  end

  def anonymise_update
    @user = User.find(id)
    authorize @user

    result = AnonymiseUser.new(user: @user).call

    if result.success?
      flash[:notice] = t("action.user.update.success_anonymised")
      redirect_to user_path(@user)
    else
      flash[:notice] = t("action.user.update.failure_anonymised")
      render :anonymise
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :organisation_id, :active, :reset_mfa, additional_organisations: [])
  end

  def id
    params[:id]
  end

  def organisation_id
    user_params[:organisation_id]
  end

  def organisation
    Organisation.find_by(id: organisation_id) || @user.organisation
  end

  def additional_organisations
    if user_params.has_key?(:additional_organisations)
      user_params[:additional_organisations].reject(&:blank?).map { |id| Organisation.find_by(id:) }
    else
      @user.additional_organisations
    end
  end

  private def service_owner
    Organisation.service_owner
  end

  private def partner_organisations
    Organisation.partner_organisations
  end
end
