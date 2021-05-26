# frozen_string_literal: true

class Staff::ActivityOtherFundingController < Staff::BaseController
  include Secured

  def show
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    @matched_efforts = @activity.matched_efforts.map { |e| MatchedEffortPresenter.new(e) }
  end
end
