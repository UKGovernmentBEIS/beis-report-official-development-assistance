# frozen_string_literal: true

class Staff::OrganisationsController < Staff::BaseController
  def index
    @organisations = policy_scope(Organisation)
    authorize @organisations
  end

  def show
    organisation = policy_scope(Organisation).find(params[:id])
    authorize organisation

    @organisation_presenter = OrganisationPresenter.new(organisation)
  end

  def new
    @organisation = policy_scope(Organisation).new
    authorize @organisation
  end

  def create
    @organisation = policy_scope(Organisation).new(organisation_params)
    authorize @organisation

    if @organisation.valid?
      @organisation.save
      flash[:notice] = I18n.t("form.organisation.create.success")
      redirect_to organisation_path(@organisation)
    else
      render :new
    end
  end

  private

  def organisation_params
    params.require(:organisation).permit(:name, :organisation_type, :default_currency, :language_code)
  end
end
