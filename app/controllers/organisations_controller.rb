# frozen_string_literal: true

class OrganisationsController < BaseController
  def index
    @role = role
    @organisations = organisations
    authorize @organisations

    add_breadcrumb t("breadcrumbs.organisation.#{@role.singularize}.index"), organisations_path(role: @role)
  end

  def show
    organisation = Organisation.find(id)
    authorize organisation

    add_breadcrumb(*breadcrumb_index(organisation))
    add_breadcrumb organisation.name, :organisation_path

    @organisation_presenter = OrganisationPresenter.new(organisation)
  end

  def new
    @organisation = Organisation.new(role: role.singularize)
    authorize @organisation

    add_breadcrumb t("breadcrumbs.organisation.#{@organisation.role}.index"), organisations_path(role: @organisation.role.pluralize)
    add_breadcrumb t("breadcrumbs.organisation.#{@organisation.role}.new"), new_organisation_path(role: role)
  end

  def create
    @organisation = Organisation.new(organisation_params)
    authorize @organisation

    if @organisation.valid?
      @organisation.save
      flash[:notice] = t("action.organisation.create.success")
      redirect_to organisation_path(@organisation)
    else
      add_breadcrumb t("breadcrumbs.organisation.#{@organisation.role}.index"), organisations_path(role: @organisation.role.pluralize)
      add_breadcrumb t("breadcrumbs.organisation.#{@organisation.role}.new"), new_organisation_path(role: @organisation.role.pluralize)
      render :new
    end
  end

  def edit
    @organisation = Organisation.find(id)
    authorize @organisation

    add_breadcrumb(*breadcrumb_index(@organisation))
    add_breadcrumb t("breadcrumbs.organisation.edit", name: @organisation.name), :edit_organisation_path
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
      add_breadcrumb(*breadcrumb_index(@organisation))
      add_breadcrumb t("breadcrumbs.organisation.edit", name: @organisation.name), :edit_organisation_path
      render :edit
    end
  end

  private def id
    params[:id]
  end

  private def role
    current_user.service_owner? ? params[:role] : "implementing_organisations"
  end

  private def organisations
    return policy_scope(Organisation).implementing.sorted_by_name if @role == "implementing_organisations"

    policy_scope(Organisation).where(role: @role.singularize).sorted_by_name
  end

  private def organisation_params
    params.require(:organisation)
      .permit(:name, :organisation_type, :default_currency, :language_code, :iati_reference, :beis_organisation_reference, :role, :active)
  end

  private def breadcrumb_index(organisation)
    if organisation.role == "service_owner"
      [t("breadcrumbs.organisation.index"), organisations_path]
    else
      [t("breadcrumbs.organisation.#{organisation.role}.index"), organisations_path(role: organisation.role.pluralize)]
    end
  end
end
