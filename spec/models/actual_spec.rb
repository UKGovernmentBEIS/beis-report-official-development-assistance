RSpec.describe Actual do
  describe "validations" do
    describe "compatibility of associated report and activity response to #is_oda?" do
      let(:oda_report) do
        create(
          :report,
          :active,
          :for_gcrf,
          description: "ODA report",
          is_oda: true
        ).tap { |report| allow(report).to receive(:is_oda?).and_return(true) }
      end

      let(:non_oda_report) do
        create(
          :report,
          :active,
          :for_ispf,
          description: "Non-ODA report with mixed activities",
          is_oda: false
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
        let(:actual) do
          build(
            :actual,
            report: non_oda_report
          )
        end

        context "and the associated ACTIVITY is ODA" do
          before { actual.parent_activity = oda_activity }

          it "is not valid" do
            actual.valid?

            expect(actual.errors[:base]).to include(
              "A non-ODA report can not include ODA actuals, and vice-versa"
            )
          end
        end

        context "and the associated ACTIVITY is non-ODA" do
          before { actual.parent_activity = non_oda_activity }

          it "is valid" do
            expect(actual.valid?).to be true
          end
        end
      end

      context "when the associated REPORT is ODA" do
        let(:actual) do
          build(
            :actual,
            report: oda_report
          )
        end

        context "and the associated ACTIVITY is ODA" do
          before { actual.parent_activity = oda_activity }

          it "is valid" do
            expect(actual.valid?).to be true
          end
        end

        context "and the associated ACTIVITY is non-ODA" do
          before { actual.parent_activity = non_oda_activity }

          it "is not valid" do
            actual.valid?

            expect(actual.errors[:base]).to include(
              "A non-ODA report can not include ODA actuals, and vice-versa"
            )
          end
        end
      end
    end

    context "with no validation context" do
      it "allows positive values" do
        actual = build(:actual, value: 10_000)
        expect(actual.valid?).to be(true)
      end

      it "does not allow negative values" do
        actual = build(:actual, value: -10_000)
        expect(actual.valid?).to be(false)
      end
    end

    context "with the `:history` validation context" do
      it "allows positive values" do
        actual = build(:actual, value: 10_000)
        expect(actual.valid?(:history)).to be(true)
      end

      it "allows negative values" do
        actual = build(:actual, value: -10_000)
        expect(actual.valid?(:history)).to be(true)
      end
    end
  end

  describe "Single table inheritance from Transaction" do
    it "should inherit from the Transaction class " do
      expect(Actual.ancestors).to include(Transaction)
      expect(Actual.table_name).to eq("transactions")
      expect(Actual.inheritance_column).to eq("type")
    end

    it "should have the _type_ of 'Actual'" do
      expect(Actual.new.type).to eq("Actual")
    end

    it "should have the _transaction_type_ of '3' for 'Disbursement'" do
      expect(Actual.new.transaction_type).to eq("3")
    end

    it "should have the _currency_ of 'GBP'" do
      expect(Actual.new.currency).to eq("GBP")
    end
  end
end
