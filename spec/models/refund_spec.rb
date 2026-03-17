require "rails_helper"

RSpec.describe Refund, type: :model do
  it { should have_one(:comment) }

  describe "Single table inheritance from Transaction" do
    it "should inherit from the Transaction class " do
      expect(Refund.ancestors).to include(Transaction)
      expect(Refund.table_name).to eq("transactions")
      expect(Refund.inheritance_column).to eq("type")
    end

    it "should have the _type_ of 'Refund'" do
      expect(Refund.new.type).to eq("Refund")
    end

    it "should have the _transaction_type_ of '3' for 'Disbursement'" do
      expect(Refund.new.transaction_type).to eq("3")
    end

    it "should have the _currency_ of 'GBP'" do
      expect(Refund.new.currency).to eq("GBP")
    end
  end

  describe "validations" do
    let(:refund) do
      Refund.new.tap do |refund|
        refund.build_comment(body: nil)
        refund.valid?
      end
    end

    it "validates associated comment with a helpful message" do
      expect(refund.errors[:comment])
        .to include("Enter a comment describing the need for the refund")
    end
  end

  describe "compatibility of associated report and activity response to #is_oda?" do
    let(:oda_report) do
      create(
        :report,
        :active,
        :for_gcrf,
        is_oda: true,
        description: "ODA report"
      ).tap { |report| allow(report).to receive(:is_oda?).and_return(true) }
    end

    let(:non_oda_report) do
      create(
        :report,
        :active,
        :for_ispf,
        is_oda: false,
        description: "Non-ODA report"
      ).tap { |report| allow(report).to receive(:is_oda?).and_return(false) }
    end

    let(:non_oda_activity) do
      create(
        :project_activity,
        :ispf_funded,
        source_fund_code: Fund.by_short_name("ISPF").id,
        title: "Non-ODA activity"
      ).tap { |activity| allow(activity).to receive(:is_oda?).and_return(false) }
    end

    let(:oda_activity) do
      create(
        :project_activity,
        :ispf_funded,
        source_fund_code: Fund.by_short_name("GCRF").id,
        title: "ODA activity"
      ).tap { |activity| allow(activity).to receive(:is_oda?).and_return(true) }
    end

    context "when the associated REPORT is non-ODA" do
      let(:refund) do
        build(
          :refund,
          report: non_oda_report
        )
      end

      context "and the associated ACTIVITY is ODA" do
        before { refund.parent_activity = oda_activity }

        it "is not valid" do
          expect(refund.valid?).to be false

          expect(refund.errors[:base]).to include(
            "A non-ODA report can not include ODA refunds, and vice-versa"
          )
        end
      end

      context "and the associated ACTIVITY is non-ODA" do
        before { refund.parent_activity = non_oda_activity }

        it "is valid" do
          expect(refund.valid?).to be true
        end
      end
    end

    context "when the associated REPORT is ODA" do
      let(:refund) do
        build(
          :refund,
          report: oda_report
        )
      end

      context "and the associated ACTIVITY is ODA" do
        before { refund.parent_activity = oda_activity }

        it "is valid" do
          expect(refund.valid?).to be true
        end
      end

      context "and the associated ACTIVITY is non-ODA" do
        before { refund.parent_activity = non_oda_activity }

        it "is not valid" do
          expect(refund.valid?).to be false

          expect(refund.errors[:base]).to include(
            "A non-ODA report can not include ODA refunds, and vice-versa"
          )
        end
      end
    end
  end

  describe "associated comment" do
    let(:refund) { create(:refund) }

    context "when the comment is edited and the refund is saved" do
      before do
        refund.comment.body = "Edited comment"
        refund.save
      end

      it "autosaves the associated comment" do
        expect(refund.comment.reload.body).to eq("Edited comment")
      end
    end
  end

  describe "#value" do
    describe "always stores a negative #value" do
      context "when given a positive value" do
        let(:refund) { create(:refund, value: "100.01") }

        it "stores a negative value" do
          expect(refund.reload.value.to_s).to eq("-100.01")
        end
      end

      context "when given a negative value" do
        let(:refund) { create(:refund, value: "-100.01") }

        it "stores a negative value" do
          expect(refund.reload.value.to_s).to eq("-100.01")
        end
      end
    end

    context "when value is missing" do
      let(:refund) { build(:refund, value: nil) }

      it "is invalid" do
        refund.valid?

        expect(refund.errors.messages[:value])
          .to eq(["Enter a refund amount", "Refund amount must be a valid number"])
      end
    end

    context "when value is not a number" do
      let(:refund) { build(:refund, value: "rubbish") }

      it "is invalid" do
        refund.valid?

        expect(refund.errors.messages[:value])
          .to eq(["Enter a refund amount", "Refund amount must be a valid number"])
      end
    end
  end
end
