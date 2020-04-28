require "rails_helper"
require "nokogiri"

RSpec.describe IngestIatiActivities do
  describe "#call" do
    it "creates 36 new projects" do
      _beis = create(:beis_organisation)
      uksa = create(:organisation, name: "UKSA", iati_reference: "GB-GOV-EA31")
      legacy_activities = File.read("#{Rails.root}/spec/fixtures/activities/uksa/real_and_complete_legacy_file.xml")

      service_object = described_class.new(delivery_partner: uksa, file_io: legacy_activities)

      expect { service_object.call }.to change { Activity.project.count }.by(36)
    end

    it "adds a new ingested flag to the activity so the team can distinguish old from new" do
      _beis = create(:beis_organisation)
      uksa = create(:organisation, name: "UKSA", iati_reference: "GB-GOV-EA31")
      legacy_activities = File.read("#{Rails.root}/spec/fixtures/activities/uksa/single_activity.xml")

      described_class.new(delivery_partner: uksa, file_io: legacy_activities).call

      new_activity = Activity.find_by(previous_identifier: "GB-GOV-13-GCRF-UKSA_NS_UKSA-019")
      expect(new_activity.ingested).to eq(true)
    end

    it "add a project with the correct parent activities" do
      beis = create(:beis_organisation)
      uksa = create(:organisation, name: "UKSA", iati_reference: "GB-GOV-EA31")
      legacy_activities = File.read("#{Rails.root}/spec/fixtures/activities/uksa/single_activity.xml")

      described_class.new(delivery_partner: uksa, file_io: legacy_activities).call

      activity = Activity.find_by(previous_identifier: "GB-GOV-13-GCRF-UKSA_NS_UKSA-019")

      # Expect a connection to the right programme
      expect(activity.parent_activity).not_to be_nil
      expect(activity.parent_activity.identifier).to eql("UKSA_NS_UKSA")
      expect(activity.parent_activity.organisation).to eql(beis)

      # Expect a connection to the right fund
      expect(activity.parent_activity.parent_activity).not_to be_nil
      expect(activity.parent_activity.parent_activity.identifier).to eq("GCRF")
      expect(activity.parent_activity.organisation).to eql(beis)
    end

    it "adds an activity with all mandatory fields" do
      beis = create(:beis_organisation)
      uksa = create(:organisation, name: "UKSA", iati_reference: "GB-GOV-EA31")
      legacy_activities = File.read("#{Rails.root}/spec/fixtures/activities/uksa/single_activity.xml")

      described_class.new(delivery_partner: uksa, file_io: legacy_activities).call

      activity = Activity.find_by(previous_identifier: "GB-GOV-13-GCRF-UKSA_NS_UKSA-019")

      expect(activity.identifier).not_to be nil
      expect(activity.identifier).not_to eq(activity.previous_identifier)
      expect(activity.organisation).to eq(uksa)
      expect(activity.reporting_organisation).to eq(beis)
      expect(activity.funding_organisation_reference).to eq(beis.iati_reference)
      expect(activity.extending_organisation).to eq(uksa)
      expect(activity.implementing_organisations.count).to eq(9)
      expect(activity.implementing_organisations.pluck(:name, :organisation_type)).to eql([
        ["Assimila", "70"],
        ["Barefoot Lightning", "70"],
        ["E2e Services", "70"],
        ["eOsphere", "70"],
        ["Geocento Limited", "70"],
        ["Geomatic Ventures", "70"],
        ["HR Wallingford", "70"],
        ["Rothamsted Research", "70"],
        ["Vivid Economics", "70"],
      ])

      expect(activity.status).to eql("3")

      expect(activity.planned_start_date).to eql(Date.new(2017, 10, 1))
      expect(activity.planned_end_date).to eql(Date.new(2018, 1, 31))
      expect(activity.actual_start_date).to eql(Date.new(2017, 10, 1))
      expect(activity.actual_end_date).to eql(Date.new(2018, 1, 31))

      expect(activity.geography).to eql("recipient_region")
      expect(activity.recipient_region).to eql("998")
      expect(activity.recipient_country).to be_nil

      expect(activity.sector).to eql("43082")
      expect(activity.flow).to eql("10")
      expect(activity.aid_type).to eql("C01")
    end

    it "creates transactions" do
      _beis = create(:beis_organisation)
      uksa = create(:organisation, name: "UKSA", iati_reference: "GB-GOV-EA31")
      legacy_activities = File.read("#{Rails.root}/spec/fixtures/activities/uksa/with_transactions.xml")

      described_class.new(delivery_partner: uksa, file_io: legacy_activities).call

      activity = Activity.find_by(previous_identifier: "GB-GOV-13-GCRF-UKSA_TZ_UKSA-021")
      transactions = Transaction.where(parent_activity: activity)

      expect(transactions.count).to eql(5)

      transaction = transactions.find_by(description: "50 schools identified for satellite instalation")
      expect(transaction.description).to eql("50 schools identified for satellite instalation")
      expect(transaction.date).to eql(Date.new(2016, 12, 16))
      expect(transaction.disbursement_channel).to eql("1")
      expect(transaction.currency).to eql("GBP")
      expect(transaction.transaction_type).to eql("3")
      expect(transaction.value.to_s).to eql("647264.0")
      expect(transaction.providing_organisation_name).to eql("UK - Department for Business, Energy and Industrial Strategy")
      expect(transaction.providing_organisation_reference).to eql("GB-GOV-13")
      expect(transaction.providing_organisation_type).to eql("10")
      expect(transaction.receiving_organisation_name).to eql("Avanti Communications")
      expect(transaction.receiving_organisation_reference).to eql(nil)
      expect(transaction.receiving_organisation_type).to eql("0")

      expect(
        transactions.find_by(description: "50 schools connected with satellite internet")
      ).not_to be_nil

      expect(
        transactions.find_by(description: "Release of the community WIFI hotspot appt, individual teachers loging functionality")
      ).not_to be_nil

      expect(
        transactions.find_by(description: "Progress report on teachers performace and WIFI community hotspot installed with solar power")
      ).not_to be_nil

      expect(
        # Trailing whitespace is deliberate and required until we can sanitise the strings
        transactions.find_by(description: "Initial proof of concept testing os remote live teaching ")
      ).not_to be_nil
    end

    context "when the activity has a country and a region" do
      it "sets the recipient region to the more granular country" do
        _beis = create(:beis_organisation)
        uksa = create(:organisation, name: "UKSA", iati_reference: "GB-GOV-EA31")
        legacy_activities = File.read("#{Rails.root}/spec/fixtures/activities/uksa/with_country.xml")

        described_class.new(delivery_partner: uksa, file_io: legacy_activities).call

        activity = Activity.find_by(previous_identifier: "GB-GOV-13-GCRF-UKSA_NG_UKSA-020")
        expect(activity.geography).to eql("recipient_country")
        expect(activity.recipient_region).to eql("289")
        expect(activity.recipient_country).to eql("NG")
      end
    end

    context "when a transaction has no description" do
      it "set a placeholder description" do
        _beis = create(:beis_organisation)
        uksa = create(:organisation, name: "UKSA", iati_reference: "GB-GOV-EA31")
        legacy_activities = File.read("#{Rails.root}/spec/fixtures/activities/uksa/with_missing_transaction_description.xml")

        described_class.new(delivery_partner: uksa, file_io: legacy_activities).call

        activity = Activity.find_by(previous_identifier: "GB-GOV-13-GCRF-UKSA_PE_UKSA-22")
        transactions = Transaction.where(parent_activity: activity)

        expect(transactions.count).to eq(11)
        transaction_without_description = transactions.find_by(value: "151340.27") # There are no remaining better identifiers
        expect(transaction_without_description.description).to eql("Unknown description")
      end
    end
  end
end
