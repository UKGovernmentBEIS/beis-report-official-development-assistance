class Users::OrganisationSessionController < ApplicationController
  include Secured

  def update
    desired_organisation_id = params[:current_user_organisation]

    if desired_organisation_id
      if current_user.all_organisations.pluck(:id).include?(desired_organisation_id)
        session[:current_user_organisation] = desired_organisation_id
      end
    end
    redirect_to current_user.service_owner? ? request.referer : root_path
  end
end
