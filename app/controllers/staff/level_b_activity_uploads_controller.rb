# frozen_string_literal: true

class Staff::LevelBActivityUploadsController < Staff::BaseController
  include Secured

  def new
    @organisation ||= Organisation.find(params[:organisation_id])
    authorize @organisation, :bulk_upload?
  end
end
