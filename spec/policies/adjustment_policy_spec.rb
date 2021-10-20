require "rails_helper"

RSpec.describe AdjustmentPolicy do
  let(:adjustment) do
    create(:adjustment, parent_activity: activity, report: report)
  end

  let(:report) { create(:report, :active) }

  subject { described_class.new(user, adjustment) }

  context "when signed in as a BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }

      it "applies the expected controls" do
        aggregate_failures do
          is_expected.to permit_action(:show)

          is_expected.to forbid_action(:new)
          is_expected.to forbid_action(:create)
        end
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }
      let(:report) do
        fund = activity.associated_fund
        create(:report, :active, fund: fund, organisation: activity.organisation)
      end

      it "applies the expected controls" do
        aggregate_failures do
          is_expected.to permit_action(:show)
          is_expected.to forbid_action(:new)
          is_expected.to forbid_action(:create)
        end
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity, organisation: create(:delivery_partner_organisation)) }

      it "applies the expected controls" do
        aggregate_failures do
          is_expected.to permit_action(:show)

          is_expected.to forbid_action(:new)
          is_expected.to forbid_action(:create)
        end
      end
    end

    context "when the activity is a third party project" do
      let(:activity) { create(:third_party_project_activity, organisation: create(:delivery_partner_organisation)) }

      it "applies the expected controls" do
        aggregate_failures do
          is_expected.to permit_action(:show)

          is_expected.to forbid_action(:new)
          is_expected.to forbid_action(:create)
        end
      end
    end
  end

  context "when signed in as a Delivery partner user" do
    let(:user) { create(:delivery_partner_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity) }

      it "applies the expected controls" do
        aggregate_failures do
          is_expected.to forbid_action(:show)
          is_expected.to forbid_action(:new)
          is_expected.to forbid_action(:create)
        end
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      it "applies the expected controls" do
        aggregate_failures do
          is_expected.to forbid_action(:show)
          is_expected.to forbid_action(:new)
          is_expected.to forbid_action(:create)
        end
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      context "and the activity does not belong to the users organisation" do
        it "applies the expected controls" do
          aggregate_failures do
            is_expected.to forbid_action(:show)
            is_expected.to forbid_action(:new)
            is_expected.to forbid_action(:create)
          end
        end
      end

      context "and the activity does belong to the users organisation" do
        before do
          activity.update(organisation: user.organisation)
        end

        context "when there is no active report" do
          let(:report) { create(:report, state: :approved) }

          it "applies the expected controls" do
            aggregate_failures do
              is_expected.to permit_action(:show)

              is_expected.to forbid_action(:new)
              is_expected.to forbid_action(:create)
            end
          end
        end

        context "when there is an active report" do
          let(:report) { create(:report, :active) }

          context "and the report is not for the organisation or fund of the activity" do
            it "applies the expected controls" do
              aggregate_failures do
                is_expected.to permit_action(:show)

                is_expected.to forbid_action(:new)
                is_expected.to forbid_action(:create)
              end
            end
          end

          context "and the report is for the organisation but not the fund of the activity" do
            before do
              report.update(organisation: activity.organisation)
            end

            it "applies the expected controls" do
              aggregate_failures do
                is_expected.to permit_action(:show)

                is_expected.to forbid_action(:new)
                is_expected.to forbid_action(:create)
              end
            end
          end

          context "and the report is for the organisation and fund of the activity" do
            before do
              report.update(organisation: activity.organisation, fund: activity.associated_fund)
            end

            context "when the report is not the one in which the transaction was created" do
              it "applies the expected controls" do
                aggregate_failures do
                  is_expected.to permit_action(:show)
                  is_expected.to permit_action(:new)
                  is_expected.to permit_action(:create)
                end
              end
            end

            context "when the report is in an editable state" do
              Report::EDITABLE_STATES.each do |state|
                before { report.update(state: state) }

                it "applies the expected controls when report in #{state} state" do
                  aggregate_failures do
                    is_expected.to permit_action(:show)
                    is_expected.to permit_action(:new)
                    is_expected.to permit_action(:create)
                  end
                end
              end
            end

            context "when the report is the one in which the transaction was created" do
              before do
                adjustment.update(report: report)
              end

              it "applies the expected controls" do
                aggregate_failures do
                  is_expected.to permit_action(:show)
                  is_expected.to permit_action(:new)
                  is_expected.to permit_action(:create)
                end
              end
            end
          end
        end
      end
    end
  end
end
