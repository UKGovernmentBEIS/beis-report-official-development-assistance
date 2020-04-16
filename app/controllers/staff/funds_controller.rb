# frozen_string_literal: true

class Staff::FundsController < Staff::ActivitiesController
  def create
    @fund = CreateFundActivity.new(organisation_id: organisation_id).call
    authorize @fund

    @fund.create_activity key: "activity.create", owner: current_user

    redirect_to activity_step_path(@fund.id, @fund.wizard_status)
  end
end
