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

    @project_activities = iati_publishable_project_activities(
      organisation: organisation,
      user: current_user
    )

    @third_party_project_activities = iati_publishable_third_party_project_activities(
      organisation: organisation,
      user: current_user
    )

    respond_to do |format|
      format.html
      format.xml do
        @activities = case level
        when "project"
          @project_activities
        when "third_party_project"
          @third_party_project_activities
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
      flash[:notice] = t("action.organisation.create.success")
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
      flash[:notice] = t("action.organisation.update.success")
      redirect_to organisation_path(@organisation)
    else
      render :edit
    end
  end

  private

  private def iati_publishable_project_activities(organisation:, user:)
    FindProjectActivities.new(
      organisation: organisation,
      user: current_user
    ).call(eager_load_parent: false).publishable_to_iati
  end

  private def iati_publishable_third_party_project_activities(organisation:, user:)
    FindThirdPartyProjectActivities.new(
      organisation: organisation,
      user: current_user
    ).call(eager_load_parent: false).publishable_to_iati
  end

  private def id
    params[:id]
  end

  private def organisation_params
    params.require(:organisation).permit(:name, :organisation_type, :default_currency, :language_code, :iati_reference)
  end

  private def level
    params[:level]
  end
end
