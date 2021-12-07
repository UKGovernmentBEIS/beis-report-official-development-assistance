RSpec.describe Export::ActivityDeliveryPartnerOrganisationColumn do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    @level_b_activity = create(:programme_activity)
    @level_c_activity = create(:project_activity)
    @level_b_activity.implementing_organisations = build_list(:implementing_organisation, 2)
    @implementing_organisations = @level_b_activity.implementing_organisations
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject { described_class.new(activities_relation: Activity.all) }

  describe "#headers" do
    it "returns the correct header" do
      expect(subject.headers).to match_array(["Delivery partner organisation"])
    end
  end

  describe "#rows" do
    context "when the activity is a level B (programme)" do
      it "returns all implementing organistion names" do
        row_value = subject.rows.fetch(@level_b_activity.id)

        implementing_organisation_name = @implementing_organisations.first.name
        other_implementing_organisation_name = @implementing_organisations.last.name

        expect(row_value).to include(Regexp.new(implementing_organisation_name))
        expect(row_value).to include(Regexp.new(other_implementing_organisation_name))
      end
    end

    context "when the activity is any other level" do
      it "returns all organistion names" do
        row_value = subject.rows.fetch(@level_c_activity.id)
        expect(row_value).to match_array(@level_c_activity.organisation.name)
      end
    end

    it "returns an errors when initialised without an ActivityRecord::Relation" do
      expect { described_class.new(activities_relation: [@level_b_activity, @level_c_activity]) }
        .to raise_error(ArgumentError)
    end
  end
end
