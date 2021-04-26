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

    @organisation_funds = funds_for_organisation_programmes(organisation_id: organisation.id)

    @project_activities = iati_publishable_project_activities(
      organisation: organisation,
      user: current_user
    )

    @third_party_project_activities = iati_publishable_third_party_project_activities(
      organisation: organisation,
      user: current_user
    )

    @funds = Activity.fund.where(form_state: "complete").order(:title)

    respond_to do |format|
      format.html do
        @grouped_programmes = Activity.programme
          .includes(:extending_organisation, :organisation, parent: [:parent])
          .where(extending_organisation: organisation)
          .order(:roda_identifier_compound)
          .group_by(&:parent)
      end

      format.xml do
        @reporting_organisation = Organisation.service_owner
        @activities = case level
        when "programme"
          return [] unless fund_id.present?
          @programmes_for_organisation_and_fund = publishable_programme_activities(
            organisation: organisation,
            user: current_user,
            fund_id: fund_id
          )
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

  private def funds_for_organisation_programmes(organisation_id:)
    fund_ids_for_organisation_programmes = Activity.where(
      level: :programme,
      extending_organisation_id: organisation_id
    ).pluck(:parent_id)
    Activity.find(fund_ids_for_organisation_programmes)
  end

  private def publishable_programme_activities(organisation:, user:, fund_id:)
    FindProgrammeActivities.new(
      organisation: organisation,
      user: current_user,
      fund_id: fund_id
    ).call
  end

  private def iati_publishable_project_activities(organisation:, user:)
    FindProjectActivities.new(
      organisation: organisation,
      user: current_user
    ).call.publishable_to_iati
  end

  private def iati_publishable_third_party_project_activities(organisation:, user:)
    FindThirdPartyProjectActivities.new(
      organisation: organisation,
      user: current_user
    ).call.publishable_to_iati
  end

  private def id
    params[:id]
  end

  private def organisation_params
    params.require(:organisation).permit(:name, :organisation_type, :default_currency, :language_code, :iati_reference, :beis_organisation_reference)
  end

  private def level
    params[:level]
  end

  private def fund_id
    params[:fund_id]
  end
end
