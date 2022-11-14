module Transfers
  extend ActiveSupport::Concern
  include Secured
  include Activities::Breadcrumbed

  included do
    before_action :can_create_transfer?
  end

  def new
    @transfer = transfer_model.new

    prepare_default_activity_trail(target_activity, tab: "transfers")
    add_breadcrumb t("breadcrumb.#{transfer_type}.new"), new_path
  end

  def edit
    @transfer = transfer_model.find(params[:id])
    authorize @transfer

    prepare_default_activity_trail(target_activity, tab: "transfers")
    add_breadcrumb t("breadcrumb.#{transfer_type}.edit"), edit_path
  end

  def create
    @transfer = transfer_model.new
    if target_activity.project? || target_activity.third_party_project?
      @transfer.report = Report.editable_for_activity(target_activity)
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
    if params[:edit]
      render edit_or_new
    else
      @transfer.save
      flash[:notice] = success_message
      redirect_to organisation_activity_transfers_path(target_activity.organisation, target_activity)
    end
  end

  def show_confirmation_or_errors
    if @transfer.valid?
      @transfer_presenter = TransferPresenter.new(@transfer)

      prepare_default_activity_trail(target_activity, tab: "transfers")
      add_breadcrumb t("breadcrumb.#{transfer_type}.confirm"), @confirmation_url

      render :confirm
    else
      render edit_or_new
    end
  end

  def edit_or_new
    (action_name == "create") ? :new : :edit
  end

  def set_confirmation_url
    @confirmation_url = (action_name == "create") ? show_path : edit_path
  end

  def edit_path
    send("activity_#{transfer_type}_path", target_activity, @transfer)
  end

  def show_path
    send("activity_#{transfer_type.to_s.pluralize}_path", target_activity)
  end

  def new_path
    send("new_activity_#{transfer_type}_path", target_activity)
  end

  def transfer_type
    transfer_model.to_s.underscore.to_sym
  end
end
