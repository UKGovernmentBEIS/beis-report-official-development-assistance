class Staff::TransfersController < Staff::BaseController
  include Secured

  helper_method :destination_roda_identifier

  def new
    @source_activity = source_activity
    @transfer = Transfer.new
    @transfer.source = @source_activity

    authorize @transfer
  end

  def create
    @transfer = Transfer.new

    authorize @transfer

    @transfer.source = source_activity
    @transfer.destination = destination_activity
    @transfer.assign_attributes(transfer_params)

    if params[:transfer][:confirm]
      confirm_or_edit
    else
      show_confirmation_or_errors
    end
  end

  def destination_roda_identifier
    params.dig(:transfer, :destination)
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

  def confirm_or_edit
    if params[:commit] == "No"
      render :new
    else
      @transfer.save
      flash[:notice] = t("action.transfer.create.success")
      redirect_to organisation_activity_path(source_activity.organisation, source_activity)
    end
  end

  def show_confirmation_or_errors
    if @transfer.valid?
      @transfer_presenter = TransferPresenter.new(@transfer)
      render :confirm
    else
      render :new
    end
  end
end
