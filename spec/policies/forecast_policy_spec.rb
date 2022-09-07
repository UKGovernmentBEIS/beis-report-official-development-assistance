require "rails_helper"

RSpec.describe ForecastPolicy do
  let(:reporting_cycle) { ReportingCycle.new(activity, 1, 2018) }
  let(:report) { Report.first }

  before do
    reporting_cycle.tick
    ForecastHistory.new(activity, financial_quarter: 2, financial_year: 2018).set_value(50)
  end

  let :forecast do
    ForecastOverview.new(activity).latest_values.last
  end

  subject { described_class.new(user, forecast) }

  context "when signed in as a BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }

      it "controls actions as expected" do
        is_expected.to permit_action(:show)

        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)

        is_expected.to forbid_action(:destroy)
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }

      it "controls actions as expected" do
        is_expected.to permit_action(:show)
        is_expected.to permit_action(:create)
        is_expected.to permit_action(:edit)
        is_expected.to permit_action(:update)
        is_expected.to permit_action(:destroy)
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      it "controls actions as expected" do
        is_expected.to permit_action(:show)

        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
      end
    end

    context "when the activity is a third party project" do
      let(:activity) { create(:third_party_project_activity) }

      it "controls actions as expected" do
        is_expected.to permit_action(:show)

        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
      end
    end
  end

  context "when signed in as a partner organisation user" do
    let(:user) { create(:delivery_partner_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity) }

      it "controls actions as expected" do
        is_expected.to forbid_action(:show)
        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      it "controls actions as expected" do
        is_expected.to forbid_action(:show)
        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      context "and the activity does not belong to the user's organisation" do
        it "controls actions as expected" do
          is_expected.to forbid_action(:show)
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
        end
      end

      context "and the activity does belong to the users organisation" do
        before do
          activity.update(organisation: user.organisation)
        end

        context "when there is no editable report" do
          before { report.update!(state: :approved) }

          it "controls actions as expected" do
            is_expected.to permit_action(:show)

            is_expected.to forbid_action(:create)
            is_expected.to forbid_action(:edit)
            is_expected.to forbid_action(:update)
            is_expected.to forbid_action(:destroy)
          end
        end

        context "when there is an editable report" do
          before { report.update!(state: :active) }

          context "and the report is not for the organisation or fund of the activity" do
            before do
              report.update!(organisation: create(:delivery_partner_organisation), fund: create(:fund_activity))
            end

            it "controls actions as expected" do
              is_expected.to permit_action(:show)

              is_expected.to forbid_action(:create)
              is_expected.to forbid_action(:edit)
              is_expected.to forbid_action(:update)
              is_expected.to forbid_action(:destroy)
            end
          end

          context "and the report is for the organisation but not the fund of the activity" do
            before do
              report.update!(fund: create(:fund_activity))
            end

            it "controls actions as expected" do
              is_expected.to permit_action(:show)

              is_expected.to forbid_action(:create)
              is_expected.to forbid_action(:edit)
              is_expected.to forbid_action(:update)
              is_expected.to forbid_action(:destroy)
            end
          end

          context "and the report is for the organisation and fund of the activity" do
            before do
              report.update!(organisation: activity.organisation, fund: activity.associated_fund)
            end

            context "when the report is not the one in which the forecast was created" do
              before do
                forecast.update!(report: create(:report))
              end

              it "controls actions as expected" do
                is_expected.to permit_action(:show)
                is_expected.to permit_action(:create)
                is_expected.to permit_action(:edit)
                is_expected.to permit_action(:update)
                is_expected.to permit_action(:destroy)
              end
            end

            context "when the report is the one in which the forecast was created" do
              it "controls actions as expected" do
                is_expected.to permit_action(:show)
                is_expected.to permit_action(:create)
                is_expected.to permit_action(:edit)
                is_expected.to permit_action(:update)
                is_expected.to permit_action(:destroy)
              end
            end
          end
        end
      end
    end
  end
end
