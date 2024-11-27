class OrganisationSessionController < ApplicationController
  def update
    if params[:current_organisation]
      if current_user.organisations.pluck(:id).include?(params[:current_organisation])
        session[:current_organisation] = params[:current_organisation]
      end
      redirect_to current_user.service_owner? ? request.referer : root_path
    end
  end
end
