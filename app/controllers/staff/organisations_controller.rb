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
    @funds = policy_scope(Fund).includes(:organisation).where(organisation: organisation)
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
    params.require(:organisation).permit(:name, :organisation_type, :default_currency, :language_code)
  end
end
