# frozen_string_literal: true

require "csv"

class Staff::SubmissionsController < Staff::BaseController
  include Secured
  include ActionController::Live

  def show
    @submission = Submission.find(id)
    authorize @submission

    respond_to do |format|
      format.html
      format.csv do
        fund = @submission.fund
        @projects = Activity.project.where(organisation: @submission.organisation).select { |activity| activity.associated_fund == fund }
        @third_party_projects = Activity.third_party_project.where(organisation: @submission.organisation).select { |activity| activity.associated_fund == fund }
        send_csv
      end
    end
  end

  def edit
    @submission = Submission.find(id)
    authorize @submission
  end

  def update
    @submission = Submission.find(id)
    authorize @submission

    @submission.assign_attributes(submission_params)
    if @submission.valid?
      @submission.save!
      @submission.create_activity key: "submission.update", owner: current_user
      activate_submission
      flash[:notice] = I18n.t("action.submission.update.success")
      redirect_to organisation_path(current_user.organisation)
    else
      render :edit
    end
  end

  private

  def id
    params[:id]
  end

  def submission_params
    params.require(:submission).permit(:deadline, :description)
  end

  def activate_submission
    if @submission.deadline.present? && @submission.deadline > Date.today
      @submission.state = :active
      @submission.save!
      @submission.create_activity key: "submission.activate", owner: current_user
    end
  end

  def send_csv
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=#{@submission.description}.csv"
    response.stream.write Activity::CSV_HEADERS.to_csv
    @projects.each do |project|
      response.stream.write ExportActivityToCsv.new(activity: project).call
    end
    @third_party_projects.each do |project|
      response.stream.write ExportActivityToCsv.new(activity: project).call
    end
    response.stream.close
  end
end
