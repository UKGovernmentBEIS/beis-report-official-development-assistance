# frozen_string_literal: true

class Staff::FundsController < Staff::ActivitiesController
  def create
    @activity = CreateFundActivity.new(organisation_id: organisation_id).call
    authorize @activity

    redirect_to activity_step_path(@activity.id, @activity.wizard_status)
  end
end
