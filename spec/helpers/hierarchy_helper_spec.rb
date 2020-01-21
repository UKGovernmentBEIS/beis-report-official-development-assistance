RSpec.describe HierarchyHelper do
  let(:organisation) { create(:organisation) }

  describe "#hierarchy_path_for" do
    context "when the item is an Activity" do
      context "when the hierarchy_type is a fund" do
        let(:fund) { create(:fund, organisation: organisation) }
        let(:fund_activity) { create(:activity, hierarchy: fund) }

        it "returns the organisation_fund_path" do
          expect(helper.hierarchy_path_for(item: fund_activity))
            .to eq(organisation_fund_path(organisation.id, fund))
        end
      end

      context "when the hierarchy_type is a programme" do
        let(:fund) { create(:fund, organisation: organisation) }
        let(:programme) { create(:programme, fund: fund) }
        let(:programme_activity) { create(:activity, hierarchy: programme) }

        it "returns the fund_programme_path" do
          expect(helper.hierarchy_path_for(item: programme_activity))
            .to eq(fund_programme_path(fund, programme))
        end
      end
    end

    context "when the item is a Transaction" do
      context "when the hierarchy_type is a fund" do
        let(:fund) { create(:fund, organisation: organisation) }
        let(:fund_transaction) { create(:transaction, hierarchy: fund) }

        it "returns the organisation_fund_path" do
          expect(helper.hierarchy_path_for(item: fund_transaction))
            .to eq(organisation_fund_path(organisation.id, fund))
        end
      end

      context "when the hierarchy_type is a programme" do
        let(:fund) { create(:fund, organisation: organisation) }
        let(:programme) { create(:programme, fund: fund) }
        let(:programme_transaction) { create(:transaction, hierarchy: programme) }

        it "returns the fund_programme_path" do
          expect(helper.hierarchy_path_for(item: programme_transaction))
            .to eq(fund_programme_path(fund, programme))
        end
      end
    end
  end

  describe "#edit_hierarchy_path_for" do
    context "when the item is an Activity" do
      context "when the hierarchy_type is a fund" do
        let(:fund) { create(:fund, organisation: organisation) }
        let(:fund_activity) { create(:activity, hierarchy: fund) }

        it "returns edit_organisation_fund_path" do
          expect(helper.edit_hierarchy_path_for(item: fund_activity))
            .to eq(edit_organisation_fund_path(organisation.id, fund))
        end
      end

      context "when the hierarchy_type is a programme" do
        let(:fund) { create(:fund, organisation: organisation) }
        let(:programme) { create(:programme, fund: fund) }
        let(:programme_activity) { create(:activity, hierarchy: programme) }

        it "returns edit_fund_programme_path" do
          expect(helper.edit_hierarchy_path_for(item: programme_activity))
            .to eq(edit_fund_programme_path(fund, programme))
        end
      end
    end

    context "when the item is a Transaction" do
      context "when the hierarchy_type is a fund" do
        let(:fund) { create(:fund, organisation: organisation) }
        let(:fund_transaction) { create(:transaction, hierarchy: fund) }

        it "returns edit_organisation_fund_path" do
          expect(helper.edit_hierarchy_path_for(item: fund_transaction))
            .to eq(edit_organisation_fund_path(organisation.id, fund))
        end
      end

      context "when the hierarchy_type is a programme" do
        let(:fund) { create(:fund, organisation: organisation) }
        let(:programme) { create(:programme, fund: fund) }
        let(:programme_transaction) { create(:transaction, hierarchy: programme) }

        it "returns edit_fund_programme_path" do
          expect(helper.edit_hierarchy_path_for(item: programme_transaction))
            .to eq(edit_fund_programme_path(fund, programme))
        end
      end
    end
  end
end
