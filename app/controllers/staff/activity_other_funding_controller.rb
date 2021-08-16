# frozen_string_literal: true

class Staff::ActivityOtherFundingController < Staff::BaseController
  include Secured
  include Activities::Breadcrumbed

  def show
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    prepare_default_activity_trail(@activity)

    @matched_efforts = @activity.matched_efforts.map { |e| MatchedEffortPresenter.new(e) }
    @external_incomes = @activity.external_incomes.map { |e| ExternalIncomePresenter.new(e) }
  end
end
