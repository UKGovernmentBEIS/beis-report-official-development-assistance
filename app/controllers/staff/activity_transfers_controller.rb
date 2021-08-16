# frozen_string_literal: true

class Staff::ActivityTransfersController < Staff::BaseController
  include Secured
  include Activities::Breadcrumbed

  def show
    activity = Activity.find(params[:activity_id])
    authorize activity

    prepare_default_activity_trail(activity)

    @activity = ActivityPresenter.new(activity)
    @outgoing_transfers = policy_scope(OutgoingTransfer.where(source: activity)).map { |transfer| TransferPresenter.new(transfer) }
    @incoming_transfers = policy_scope(IncomingTransfer.where(destination: activity)).map { |transfer| TransferPresenter.new(transfer) }
  end
end
