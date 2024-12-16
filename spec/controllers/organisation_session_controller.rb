require "rails_helper"

RSpec.describe OrganisationSessionController do
  let(:user) { create(:partner_organisation_user, organisation: organisation) }
  let(:organisation) { create(:partner_organisation) }
  let(:other_organisation) { create(:partner_organisation) }

  before do
    allow(controller).to receive(:current_user).and_return(user)

    user.additional_organisations << [create(:partner_organisation), create(:partner_organisation)]
  end

  describe "#update" do
    it "sets the session `current_user_organisation` to the user's primary organisation's ID" do
      put :update, params: build_params(user.primary_organisation.id)

      expect(session[:current_user_organisation]).to eq(user.primary_organisation.id)
    end

    it "sets the session `current_user_organisation` to an ID from the user's additional organisations" do
      id = user.additional_organisations.pluck(:id).sample

      put :update, params: build_params(id)

      expect(session[:current_user_organisation]).to eq(id)
    end

    it "does not set the session `current_user_organisation` to a random ID" do
      random_id = SecureRandom.uuid

      put :update, params: build_params(random_id)

      expect(session[:current_user_organisation]).not_to eq(random_id)
    end

    it "does not set the session `current_user_organisation` to an organisation ID not in the user's additional organisations" do
      put :update, params: build_params(other_organisation.id)

      expect(session[:current_user_organisation]).not_to eq(other_organisation.id)
    end

    def build_params(id)
      {current_user_organisation: id}
    end
  end
end
