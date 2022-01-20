require "rails_helper"

RSpec.describe Activity::GroupedActivitiesFetcher do
  let(:user) { create(:beis_user) }

  context "when the organisation is a service owner" do
    let(:organisation) { create(:beis_organisation) }

    it "groups all programmes by parent" do
      fund = create(:fund_activity)
      programme = create(:programme_activity, parent: fund)
      project = create(:project_activity, parent: programme)
      third_party_project = create(:third_party_project_activity, parent: project)

      activities = described_class.new(user: user, organisation: organisation).call

      expect(activities).to eq({
        fund => {
          programme => {
            project => [
              third_party_project
            ]
          }
        }
      })
    end

    it "only includes scoped activities if a scope is provided" do
      fund = create(:fund_activity)
      non_current_programme = create(:programme_activity, programme_status: "completed", parent: fund)
      non_current_project_1 = create(:project_activity, programme_status: "completed", parent: non_current_programme)

      programme = create(:programme_activity, parent: fund)
      project = create(:project_activity, parent: programme)
      third_party_project = create(:third_party_project_activity, parent: project)

      _non_current_project_2 = create(:project_activity, parent: programme, programme_status: "stopped")
      _non_current_third_party_project = create(:third_party_project_activity, parent: project, programme_status: "stopped")

      completed_activities = described_class.new(user: user, organisation: organisation, scope: :current).call
      historic_activities = described_class.new(user: user, organisation: organisation, scope: :historic).call

      expect(completed_activities).to eq({
        fund => {
          programme => {
            project => [
              third_party_project
            ]
          }
        }
      })

      expect(historic_activities).to eq({
        fund => {
          non_current_programme => {
            non_current_project_1 => []
          }
        }
      })
    end
  end

  context "when the organisation is not a service owner" do
    let(:organisation) { create(:delivery_partner_organisation) }

    it "filters by extending organisation" do
      fund = create(:fund_activity)
      programme = create(:programme_activity, extending_organisation: organisation, parent: fund)
      project = create(:project_activity, parent: programme, extending_organisation: organisation)
      third_party_project = create(:third_party_project_activity, parent: project, extending_organisation: organisation)

      other_programme = create(:programme_activity, parent: fund)
      _other_project = create(:project_activity, parent: other_programme)

      activities = described_class.new(user: user, organisation: organisation).call

      expect(activities).to eq({
        fund => {
          programme => {
            project => [
              third_party_project
            ]
          }
        }
      })
    end
  end

  it "orders the activities by created date" do
    organisation = create(:delivery_partner_organisation)
    fund = create(:fund_activity)
    old_programme = create(:programme_activity, extending_organisation: organisation, parent: fund, created_at: 1.month.ago)
    new_programme = create(:programme_activity, extending_organisation: organisation, parent: fund, created_at: 3.days.ago)

    old_project_1 = create(:project_activity, extending_organisation: organisation, parent: old_programme, created_at: 10.days.ago)
    new_project_1 = create(:project_activity, extending_organisation: organisation, parent: old_programme, created_at: 7.days.ago)

    old_project_2 = create(:project_activity, extending_organisation: organisation, parent: new_programme, created_at: 4.days.ago)
    new_project_2 = create(:project_activity, extending_organisation: organisation, parent: new_programme, created_at: 2.days.ago)

    old_third_party_project = create(:third_party_project_activity, extending_organisation: organisation, parent: old_project_2, created_at: 1.days.ago)
    new_third_party_project = create(:third_party_project_activity, extending_organisation: organisation, parent: old_project_2)

    activities = described_class.new(user: create(:beis_user), organisation: organisation).call

    expect(activities).to eq({
      fund => {
        old_programme => {
          old_project_1 => [],
          new_project_1 => []
        },
        new_programme => {
          old_project_2 => [
            old_third_party_project,
            new_third_party_project
          ],
          new_project_2 => []
        }
      }
    })
  end
end
