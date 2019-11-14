# frozen_string_literal: true

class Staff::OrganisationsController < Staff::BaseController
  include Secured

  def index
    @organisations = Organisation.all
  end

  def show
    organisation = Organisation.find(params[:id])
    @organisation_presenter = OrganisationPresenter.new(organisation)
  end

  def new
    @organisation = Organisation.new
  end

  def create
    @organisation = Organisation.new(organisation_params)

    if @organisation.valid?
      @organisation.save
      flash[:notice] = I18n.t("create_organisation.create.success")
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
