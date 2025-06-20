require "rails_helper"

RSpec.describe BudgetPolicy do
  let(:budget) { create(:budget, parent_activity: activity, budget_type: "direct") }

  subject { described_class.new(user, budget) }

  context "when signed in as a BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }

      it "permits all actions" do
        is_expected.to permit_action(:show)
        is_expected.to permit_action(:create)
        is_expected.to permit_action(:edit)
        is_expected.to permit_action(:update)
        is_expected.to permit_action(:destroy)
        is_expected.to permit_action(:revisions)
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }

      it "permits all actions" do
        is_expected.to permit_action(:show)
        is_expected.to permit_action(:create)
        is_expected.to permit_action(:edit)
        is_expected.to permit_action(:update)
        is_expected.to permit_action(:destroy)
        is_expected.to permit_action(:revisions)
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      it "only permits show and revisions" do
        is_expected.to permit_action(:show)
        is_expected.to permit_action(:revisions)

        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
      end
    end

    context "when the activity is a third party project" do
      let(:activity) { create(:third_party_project_activity) }

      it "only permits show and revisions" do
        is_expected.to permit_action(:show)
        is_expected.to permit_action(:revisions)

        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
      end
    end
  end

  context "when signed in as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity) }

      it "forbids all actions" do
        is_expected.to forbid_action(:show)
        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
        is_expected.to forbid_action(:revisions)
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      it "forbids all actions" do
        is_expected.to forbid_action(:show)
        is_expected.to forbid_action(:create)
        is_expected.to forbid_action(:edit)
        is_expected.to forbid_action(:update)
        is_expected.to forbid_action(:destroy)
        is_expected.to forbid_action(:revisions)
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      context "and the activity does not belong to the users organisation" do
        it "forbids all actions" do
          is_expected.to forbid_action(:show)
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
          is_expected.to forbid_action(:revisions)
        end
      end

      context "and the activity does belong to the users organisation" do
        before do
          activity.update(organisation: user.organisation)
        end

        context "when there is no editable report" do
          let(:report) { create(:report, :approved) }

          it "only permits show and revisions" do
            is_expected.to permit_action(:show)
            is_expected.to permit_action(:revisions)

            is_expected.to forbid_action(:create)
            is_expected.to forbid_action(:edit)
            is_expected.to forbid_action(:update)
            is_expected.to forbid_action(:destroy)
          end
        end

        context "when there is an editable report" do
          let(:report) { create(:report, :active) }

          context "and the report is not for the organisation or fund of the activity" do
            it "only permits show and revisions" do
              is_expected.to permit_action(:show)
              is_expected.to permit_action(:revisions)

              is_expected.to forbid_action(:create)
              is_expected.to forbid_action(:edit)
              is_expected.to forbid_action(:update)
              is_expected.to forbid_action(:destroy)
            end
          end

          context "and the report is for the organisation but not the fund of the activity" do
            before do
              report.update(organisation: activity.organisation)
            end

            it "only permits show and revisions" do
              is_expected.to permit_action(:show)
              is_expected.to permit_action(:revisions)

              is_expected.to forbid_action(:create)
              is_expected.to forbid_action(:edit)
              is_expected.to forbid_action(:update)
              is_expected.to forbid_action(:destroy)
            end
          end

          context "and the report is for the organisation and fund of the activity" do
            before do
              report.update(organisation: activity.organisation, fund: activity.associated_fund)
            end

            context "when the report is not the one in which the budget was created" do
              it "permits all actions" do
                is_expected.to permit_action(:show)
                is_expected.to permit_action(:create)
                is_expected.to permit_action(:revisions)
                is_expected.to permit_action(:edit)
                is_expected.to permit_action(:update)
                is_expected.to permit_action(:destroy)
              end
            end

            context "when the report is the one in which the budget was created" do
              before do
                budget.update(report: report)
              end

              it "permits all actions" do
                is_expected.to permit_action(:show)
                is_expected.to permit_action(:create)
                is_expected.to permit_action(:edit)
                is_expected.to permit_action(:update)
                is_expected.to permit_action(:destroy)
                is_expected.to permit_action(:revisions)
              end
            end
          end
        end
      end
    end
  end
end
