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

    project_activities = FindProjectActivities.new(organisation: organisation, user: current_user).call(eager_load_parent: false)
    third_party_project_activities = FindThirdPartyProjectActivities.new(organisation: organisation, user: current_user).call

    respond_to do |format|
      format.html do
        @project_activities = project_activities.map { |activity| ActivityPresenter.new(activity) }
        @third_party_project_activities = third_party_project_activities.map { |activity| ActivityPresenter.new(activity) }
      end
      format.xml do
        @activities = case level
        when "project"
          project_activities.publishable_to_iati.map { |activity| ActivityXmlPresenter.new(activity) }
        when "third_party_project"
          third_party_project_activities.publishable_to_iati.map { |activity| ActivityXmlPresenter.new(activity) }
        else
          []
        end
        response.headers["Content-Disposition"] = "attachment; filename=\"#{organisation.iati_reference}.xml\""
      end
    end
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
      flash[:notice] = I18n.t("action.organisation.create.success")
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
      flash[:notice] = I18n.t("action.organisation.update.success")
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

  def level
    params[:level]
  end
end
