module Transfers
  extend ActiveSupport::Concern
  include Secured

  included do
    before_action :can_create_transfer?
  end

  def new
    @transfer = transfer_model.new
  end

  def edit
    @transfer = transfer_model.find(params[:id])
    authorize @transfer
  end

  def create
    @transfer = transfer_model.new
    if source_activity.project? || source_activity.third_party_project?
      @transfer.report = Report.editable_for_activity(source_activity)
    end
    @transfer.assign_attributes(transfer_params)

    if params[transfer_type][:confirm]
      confirm_or_edit(t("action.#{transfer_type}.create.success"))
    else
      set_confirmation_url
      show_confirmation_or_errors
    end
  end

  def update
    @transfer = transfer_model.find(params[:id])
    authorize @transfer

    @transfer.assign_attributes(transfer_params)

    if params[transfer_type][:confirm]
      confirm_or_edit(t("action.#{transfer_type}.update.success"))
    else
      set_confirmation_url
      show_confirmation_or_errors
    end
  end

  private

  def confirm_or_edit(success_message)
    if params[:commit] == "No"
      render edit_or_new
    else
      @transfer.save
      flash[:notice] = success_message
      redirect_to organisation_activity_path(source_activity.organisation, source_activity)
    end
  end

  def show_confirmation_or_errors
    if @transfer.valid?
      @transfer_presenter = TransferPresenter.new(@transfer)
      render :confirm
    else
      render edit_or_new
    end
  end

  def edit_or_new
    action_name == "create" ? :new : :edit
  end

  def set_confirmation_url
    @confirmation_url = if action_name == "create"
      send("activity_#{transfer_type.to_s.pluralize}_path", @source_activity)
    else
      send("activity_#{transfer_type}_path", @transfer.source, @transfer)
    end
  end

  def transfer_type
    transfer_model.to_s.underscore.to_sym
  end
end
