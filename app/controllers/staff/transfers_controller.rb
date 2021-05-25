class Staff::TransfersController < Staff::BaseController
  include Secured

  helper_method :destination_roda_identifier

  def new
    @source_activity = source_activity

    authorize @source_activity, :create_transfer?

    @transfer = Transfer.new
    @transfer.source = @source_activity
  end

  def edit
    @transfer = Transfer.find(params[:id])
    @destination_roda_identifier = @transfer.destination.roda_identifier
    authorize @transfer
  end

  def create
    authorize source_activity, :create_transfer?

    @transfer = Transfer.new
    @transfer.source = source_activity
    if source_activity.project? || source_activity.third_party_project?
      @transfer.report = Report.editable_for_activity(source_activity)
    end
    @transfer.destination = destination_activity
    @transfer.assign_attributes(transfer_params)

    if params[:transfer][:confirm]
      confirm_or_edit(t("action.transfer.create.success"))
    else
      @confirmation_url = activity_transfers_path(@source_activity)
      show_confirmation_or_errors
    end
  end

  def update
    @transfer = Transfer.find(params[:id])
    authorize @transfer

    @transfer.destination = destination_activity
    @transfer.assign_attributes(transfer_params)

    if params[:transfer][:confirm]
      confirm_or_edit(t("action.transfer.update.success"))
    else
      @confirmation_url = activity_transfer_path(@transfer.source, @transfer)
      show_confirmation_or_errors
    end
  end

  def destination_roda_identifier
    @destination_roda_identifier || params.dig(:transfer, :destination)
  end

  private

  def source_activity_id
    params[:activity_id]
  end

  def transfer_params
    params.require(:transfer)
      .permit(
        :financial_quarter,
        :financial_year,
        :value,
      )
  end

  def source_activity
    @source_activity ||= Activity.find(source_activity_id)
  end

  def destination_activity
    @destination_activity ||= Activity.by_roda_identifier(destination_roda_identifier)
  end

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
end
