require "rails_helper"

RSpec.describe "Rollout UI", type: :request do
  before do
    stub_const("ROLLOUT", Rollout.new(Redis.new))
    Rollout::UI.configure do
      instance { ROLLOUT }
    end
  end

  context "for a visitor" do
    it "returns 404" do
      expect { get "/rollout" }.to raise_error(ActionController::RoutingError)
    end
  end

  context "for a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }
    before do
      login_as(user)
    end
    after { logout }

    it "returns 404" do
      expect { get "/rollout" }.to raise_error(ActionController::RoutingError)
    end
  end

  context "for a service owner" do
    let(:user) { create(:beis_user) }
    before do
      login_as(user)
    end
    after { logout }

    it "returns 200" do
      get "/rollout"
      expect(response).to be_ok
    end
  end
end
