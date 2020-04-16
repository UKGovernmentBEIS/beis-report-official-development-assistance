# frozen_string_literal: true

class Staff::OrganisationsController < Staff::BaseController
  def index
    @organisations = policy_scope(Organisation)
    authorize @organisations
  end

  def show
    organisation = Organisation.find(id)
    authorize organisation

    @organisation_presenter = OrganisationPresenter.new(organisation)

    if organisation.service_owner
      fund_activities = policy_scope(Activity.funds, policy_scope_class: FundPolicy::Scope).includes(:organisation).order("created_at ASC")
      programme_activities = policy_scope(Activity.programme, policy_scope_class: ProgrammePolicy::Scope).includes(:organisation).order("created_at ASC")
      project_activities = policy_scope(Activity.project, policy_scope_class: ProjectPolicy::Scope).includes(:organisation).order("created_at ASC")
    else
      fund_activities = policy_scope(Activity.funds, policy_scope_class: FundPolicy::Scope).includes(:organisation).where(organisation: organisation).order("created_at ASC")
      programme_activities = policy_scope(Activity.programme, policy_scope_class: ProgrammePolicy::Scope).includes(:organisation).where(extending_organisation: organisation).order("created_at ASC")
      project_activities = policy_scope(Activity.project, policy_scope_class: ProjectPolicy::Scope).includes(:organisation).where(organisation: organisation).order("created_at ASC")
    end

    @fund_activities = fund_activities.map { |activity| ActivityPresenter.new(activity) }
    @programme_activities = programme_activities.map { |activity| ActivityPresenter.new(activity) }
    @project_activities = project_activities.map { |activity| ActivityPresenter.new(activity) }
  end

  def new
    @organisation = Organisation.new
    authorize @organisation
  end

  def create
    @organisation = Organisation.new(organisation_params)
    authorize @organisation

    if @organisation.valid?
      @organisation.save
      @organisation.create_activity key: "organisation.create", owner: current_user
      flash[:notice] = I18n.t("form.organisation.create.success")
      redirect_to organisation_path(@organisation)
    else
      render :new
    end
  end

  def edit
    @organisation = Organisation.find(id)
    authorize @organisation
  end

  def update
    @organisation = Organisation.find(id)
    authorize @organisation

    @organisation.assign_attributes(organisation_params)

    if @organisation.valid?
      @organisation.save
      @organisation.create_activity key: "organisation.update", owner: current_user
      flash[:notice] = I18n.t("form.organisation.update.success")
      redirect_to organisation_path(@organisation)
    else
      render :edit
    end
  end

  private

  def id
    params[:id]
  end

  def organisation_params
    params.require(:organisation).permit(:name, :organisation_type, :default_currency, :language_code, :iati_reference)
  end
end
