# frozen_string_literal: true

class Staff::OrganisationsController < Staff::BaseController
  def index
    @role = params[:role]
    @organisations = policy_scope(Organisation).where(role: @role.singularize)
    authorize @organisations
  end

  def show
    organisation = Organisation.find(id)
    authorize organisation

    @organisation_presenter = OrganisationPresenter.new(organisation)
  end

  def new
    @organisation = Organisation.new(role: params[:role].singularize)
    authorize @organisation
  end

  def create
    @organisation = Organisation.new(organisation_params)
    authorize @organisation

    if @organisation.valid?
      @organisation.save
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
      flash[:notice] = t("action.organisation.update.success")
      redirect_to organisation_path(@organisation)
    else
      render :edit
    end
  end

  private def id
    params[:id]
  end

  private def organisation_params
    params.require(:organisation)
      .permit(:name, :organisation_type, :default_currency, :language_code, :iati_reference, :beis_organisation_reference, :role, :active)
  end
end
