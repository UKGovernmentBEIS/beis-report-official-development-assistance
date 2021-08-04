# frozen_string_literal: true

class Staff::ActivityDetailsController < Staff::BaseController
  include Secured
  include Breadcrumbed

  def show
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    prepare_default_activity_trail(@activity)

    @activities = @activity.child_activities.order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }
    @implementing_organisation_presenters = @activity.implementing_organisations.map { |implementing_organisation| ImplementingOrganisationPresenter.new(implementing_organisation) }
  end
end
