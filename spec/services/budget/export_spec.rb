RSpec.describe Budget::Export do
  subject { described_class.new(source_fund: fund) }

  let(:fund) { Fund.by_short_name("NF") }
  let(:activity_stub) { double("ActiveRecord::Relation") }

  let(:activities) { build_list(:project_activity, 5, budgets: budgets) }
  let(:budgets) do
    [
      build(:budget, financial_year: 2018, value: 100),
      build(:budget, financial_year: 2019, value: 80),
      build(:budget, financial_year: 2020, value: 75),
      build(:budget, financial_year: 2021, value: 20),
    ]
  end

  before(with_activities: true) do
    allow(Activity).to receive(:includes).with(:budgets).and_return(activity_stub)
    allow(activity_stub).to receive(:not_fund).and_return(activity_stub)
    allow(activity_stub).to receive(:where).with(source_fund_code: fund.id).and_return(activities)
  end

  describe "#filename" do
    it "returns the filename" do
      expect(subject.filename).to eq("NF_budgets.csv")
    end
  end

  describe "#headers" do
    context "when there are no activities" do
      it "returns just the headers" do
        expect(subject.headers).to eq(Budget::Export::HEADERS)
      end
    end

    context "when there are activities present", :with_activities do
      it "returns the headers and the relevant financial years" do
        expect(subject.headers).to eq(Budget::Export::HEADERS + [
          "2018-2019",
          "2019-2020",
          "2020-2021",
          "2021-2022",
        ])
      end

      context "when there are no budgets present" do
        let(:activities) { build_list(:project_activity, 5) }

        it "returns just the headers" do
          expect(subject.headers).to eq(Budget::Export::HEADERS)
        end
      end
    end
  end

  describe "#rows" do
    context "when there are no activities" do
      it "returns an empty array" do
        expect(subject.rows).to eq([])
      end
    end

    context "when there are activities present", :with_activities do
      let(:activity1) { build(:project_activity, budgets: activity_1_budgets) }
      let(:activity2) { build(:project_activity, budgets: activity_2_budgets) }
      let(:activities) { [activity1, activity2] }

      let(:activity_1_budgets) do
        [
          build(:budget, financial_year: 2018, value: 100),
          build(:budget, financial_year: 2019, value: 80),
          build(:budget, financial_year: 2021, value: 20),
        ]
      end

      let(:activity_2_budgets) do
        [
          build(:budget, financial_year: 2018, value: 100),
          build(:budget, financial_year: 2019, value: 80),
          build(:budget, financial_year: 2020, value: 75),
          build(:budget, financial_year: 2021, value: 20),
        ]
      end

      it "returns the budgets for the activities" do
        expect(subject.rows).to match_array([
          [
            activity1.roda_identifier,
            activity1.delivery_partner_identifier,
            "Project (level C)",
            activity1.title,
            "100.00",
            "80.00",
            "0.00",
            "20.00",
          ],
          [
            activity2.roda_identifier,
            activity2.delivery_partner_identifier,
            "Project (level C)",
            activity2.title,
            "100.00",
            "80.00",
            "75.00",
            "20.00",
          ],
        ])
      end

      context "when there are no budgets present" do
        let(:activities) { build_list(:project_activity, 5) }

        it "returns an empty array" do
          expect(subject.rows).to eq([])
        end
      end
    end
  end
end
