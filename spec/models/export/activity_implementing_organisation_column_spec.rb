RSpec.describe Export::ActivityImplementingOrganisationColumn do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @activity_with_single_organisation = activity_with_single_organisation
    @activity_with_multiple_organisations = activity_with_multiple_organisations
    @level_b_activity_with_extending_organisation = level_b_activity_with_extending_organisation
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "when there are activities" do
    subject { described_class.new(activities_relation: Activity.all) }

    describe "#headers" do
      it "returns the correct header" do
        expect(subject.headers).to match_array(["Implementing organisations"])
      end
    end

    describe "#rows" do
      context "when the activity is level C (project)" do
        context "when the activity has only a single implementing organisation" do
          it "returns the name of the organisation" do
            row_value = subject.rows.fetch(@activity_with_single_organisation.id)
            organisation_name = @activity_with_single_organisation.implementing_organisations.first.name

            expect(row_value).to eq [organisation_name]
          end
        end

        context "when the activity has multiple implementing organisations" do
          it "returns all implementing organistion names sperated with a pipe (|)" do
            row_value = subject.rows.fetch(@activity_with_multiple_organisations.id)

            expect(row_value.first).to include("|")

            implementing_organisation_name =
              @activity_with_multiple_organisations.implementing_organisations.first.name
            other_implementing_organisation_name =
              @activity_with_multiple_organisations.implementing_organisations.last.name
            implementing_organisations_names = row_value.first.split("|")

            expect(implementing_organisations_names).to include(implementing_organisation_name)
            expect(implementing_organisations_names).to include(other_implementing_organisation_name)
          end
        end
      end

      context "when the activity is level B (programme)" do
        it "returns the name of the extending organisation which is considered the implementing organisation" do
          row_value = subject.rows.fetch(@level_b_activity_with_extending_organisation.id)
          organisation_name = @level_b_activity_with_extending_organisation.extending_organisation.name

          expect(row_value).to eq [organisation_name]
        end
      end
    end
  end

  context "when there are no activities" do
    subject { described_class.new(activities_relation: Activity.none) }

    describe "#headers" do
      it "returns the header" do
        expect(subject.headers).to match_array(["Implementing organisations"])
      end
    end

    describe "#rows" do
      it "returns an empty array" do
        expect(subject.rows).to eq []
      end
    end
  end

  context "when the activities are not an Activerecord::Relation" do
    it "raises an argument error" do
      expect { described_class.new(activities_relation: []) }.to raise_error(ArgumentError)
    end
  end

  def activity_with_single_organisation
    activity = create(:project_activity)
    organisation = create(:implementing_organisation)
    activity.implementing_organisations = [organisation]
    activity
  end

  def activity_with_multiple_organisations
    activity = create(:project_activity)
    organisations = create_list(:implementing_organisation, 2)
    activity.implementing_organisations = organisations
    activity
  end

  def level_b_activity_with_extending_organisation
    organisation = create(:delivery_partner_organisation)
    create(:programme_activity, extending_organisation: organisation)
  end
end
