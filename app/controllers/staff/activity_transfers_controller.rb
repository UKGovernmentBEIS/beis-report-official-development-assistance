# frozen_string_literal: true

class Staff::ActivityTransfersController < Staff::BaseController
  include Secured

  def show
    activity = Activity.find(params[:activity_id])
    authorize activity

    @activity = ActivityPresenter.new(activity)
    @outgoing_transfers = policy_scope(OutgoingTransfer.where(source: activity)).map { |transfer| TransferPresenter.new(transfer) }
    @incoming_transfers = policy_scope(IncomingTransfer.where(destination: activity)).map { |transfer| TransferPresenter.new(transfer) }
  end
end
