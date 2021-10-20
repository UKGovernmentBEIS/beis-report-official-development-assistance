require "rails_helper"

RSpec.describe RefundPolicy do
  let(:refund) { create(:refund, parent_activity: activity) }

  subject { described_class.new(user, refund) }

  context "when signed in as a BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }

      it "controls actions as expected" do
        aggregate_failures do
          is_expected.to permit_action(:show)
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)

          is_expected.to forbid_action(:destroy)
        end
      end
    end

    context "when the activity is a programme" do
      context "and the activity has an associated report" do
        let(:activity) { create(:programme_activity, :with_report, organisation: user.organisation) }

        it "controls actions as expected" do
          aggregate_failures do
            is_expected.to permit_action(:show)
            is_expected.to permit_action(:create)
            is_expected.to permit_action(:edit)
            is_expected.to permit_action(:update)
            is_expected.to permit_action(:destroy)
          end
        end
      end

      context "and the activity does not have an associated report" do
        let(:activity) { create(:programme_activity, organisation: user.organisation) }

        it "controls actions as expected" do
          aggregate_failures do
            is_expected.to permit_action(:show)
            is_expected.to forbid_action(:create)
            is_expected.to permit_action(:edit)
            is_expected.to permit_action(:update)
            is_expected.to permit_action(:destroy)
          end
        end
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity, organisation: create(:delivery_partner_organisation)) }

      it "controls actions as expected" do
        aggregate_failures do
          is_expected.to permit_action(:show)

          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
        end
      end
    end

    context "when the activity is a third party project" do
      let(:activity) { create(:third_party_project_activity, organisation: create(:delivery_partner_organisation)) }

      it "controls actions as expected" do
        aggregate_failures do
          is_expected.to permit_action(:show)

          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
        end
      end
    end
  end

  context "when signed in as a Delivery partner user" do
    let(:user) { create(:delivery_partner_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity) }

      it "controls actions as expected" do
        aggregate_failures do
          is_expected.to forbid_action(:show)
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
        end
      end
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      it "controls actions as expected" do
        aggregate_failures do
          is_expected.to forbid_action(:show)
          is_expected.to forbid_action(:create)
          is_expected.to forbid_action(:edit)
          is_expected.to forbid_action(:update)
          is_expected.to forbid_action(:destroy)
        end
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      context "and the activity does not belong to the users organisation" do
        it "controls actions as expected" do
          aggregate_failures do
            is_expected.to forbid_action(:show)
            is_expected.to forbid_action(:create)
            is_expected.to forbid_action(:edit)
            is_expected.to forbid_action(:update)
            is_expected.to forbid_action(:destroy)
          end
        end
      end

      context "and the activity does belong to the users organisation" do
        before do
          activity.update(organisation: user.organisation)
        end

        context "when there is no editable report" do
          let(:report) { create(:report, state: :approved) }

          it "controls actions as expected" do
            aggregate_failures do
              is_expected.to permit_action(:show)

              is_expected.to forbid_action(:create)
              is_expected.to forbid_action(:edit)
              is_expected.to forbid_action(:update)
              is_expected.to forbid_action(:destroy)
            end
          end
        end

        context "when there is an editable report" do
          let(:report) { create(:report, :active) }

          context "and the report is not for the organisation or fund of the activity" do
            it "controls actions as expected" do
              aggregate_failures do
                is_expected.to permit_action(:show)

                is_expected.to forbid_action(:create)
                is_expected.to forbid_action(:edit)
                is_expected.to forbid_action(:update)
                is_expected.to forbid_action(:destroy)
              end
            end
          end

          context "and the report is for the organisation but not the fund of the activity" do
            before do
              report.update(organisation: activity.organisation)
            end

            it "controls actions as expected" do
              aggregate_failures do
                is_expected.to permit_action(:show)

                is_expected.to forbid_action(:create)
                is_expected.to forbid_action(:edit)
                is_expected.to forbid_action(:update)
                is_expected.to forbid_action(:destroy)
              end
            end
          end

          context "and the report is for the organisation and fund of the activity" do
            before do
              report.update(organisation: activity.organisation, fund: activity.associated_fund)
            end

            context "when the report is not the one in which the actual was created" do
              it "controls actions as expected" do
                aggregate_failures do
                  is_expected.to permit_action(:show)
                  is_expected.to permit_action(:create)

                  is_expected.to forbid_action(:edit)
                  is_expected.to forbid_action(:update)
                  is_expected.to forbid_action(:destroy)
                end
              end
            end

            context "when the report is the one in which the actual was created" do
              before do
                refund.update(report: report)
              end

              it "controls actions as expected" do
                aggregate_failures do
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
end
