require "rails_helper"

RSpec.describe "Fix extending_organisation inconsistencies" do
  let(:beis) { create(:beis_organisation) }
  let(:delivery_partner) { create(:delivery_partner_organisation) }

  describe "with a fund" do
    let!(:activity) { create(:fund_activity, organisation: delivery_partner, extending_organisation: delivery_partner) }

    it "sets the organisation and extending_organisation to BEIS" do
      run_data_migration

      expect(activity.organisation).to eql(beis)
      expect(activity.extending_organisation).to eql(beis)
    end
  end

  describe "with a programme" do
    let!(:activity) { create(:programme_activity, organisation: delivery_partner, extending_organisation: delivery_partner) }

    it "sets the organisation to BEIS" do
      run_data_migration

      expect(activity.organisation).to eql(beis)
    end

    it "doesn't update the organisation if the extending_organisation is BEIS and outputs a warning" do
      activity.update(extending_organisation: beis)

      expect { run_data_migration }.to output(/Found 1 programme/).to_stdout

      expect(activity.organisation).to eql(delivery_partner)
    end
  end

  describe "with a project" do
    let!(:activity) { create(:project_activity, organisation: delivery_partner, extending_organisation: beis) }

    it "sets the extending_organisation to the delivery_partner (copied from organisation)" do
      run_data_migration

      expect(activity.extending_organisation).to eql(delivery_partner)
    end
  end

  describe "with a third-party project" do
    let!(:activity) { create(:third_party_project_activity, organisation: delivery_partner, extending_organisation: beis) }

    it "sets the extending_organisation to the delivery_partner (copied from organisation)" do
      run_data_migration

      expect(activity.extending_organisation).to eql(delivery_partner)
    end
  end

  private

  def run_data_migration
    load(Rails.root.join("db", "data", "20210412134546_fix_extending_organisation_inconsistencies.rb"))

    activity.reload
  end
end
