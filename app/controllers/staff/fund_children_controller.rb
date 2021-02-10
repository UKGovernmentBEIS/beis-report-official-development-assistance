# frozen_string_literal: true

class Staff::FundChildrenController < Staff::BaseController
  include Secured

  def create
    fund = Fund.new(params[:source_fund_id])
    authorize fund

    programme = CreateProgramme.new(
      organisation_id: params[:organisation_id],
      source_fund_id: params[:source_fund_id]
    ).call

    redirect_to activity_step_path(programme.id, programme.form_state)
  end
end
