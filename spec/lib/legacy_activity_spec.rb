require "rails_helper"
require "legacy_activity"

RSpec.describe LegacyActivity do
  let(:delivery_partner) { create(:delivery_partner_organisation) }
  let(:activity_node_set) do
    Nokogiri::XML(
      File.read("#{Rails.root}/spec/fixtures/activities/uksa/single_activity.xml"),
      nil,
      "UTF-8"
    ).xpath("//iati-activity").first
  end

  describe "#elements" do
    it "returns the nokogiri nodes for this document" do
      result = described_class.new(activity_node_set: activity_node_set, delivery_partner: delivery_partner).elements
      expect(result.class).to eql(Nokogiri::XML::NodeSet)
    end
  end

  describe "#to_xml" do
    it "returns the xml representation for this document" do
      legacy_xml = File.read("#{Rails.root}/spec/fixtures/activities/uksa/individual_activity.xml")

      result = described_class.new(activity_node_set: activity_node_set, delivery_partner: delivery_partner).to_xml

      expect(result.squish).to eql(legacy_xml.squish)
    end
  end

  describe "#identifier" do
    context "when there is an identifier element" do
      it "returns the full IATI identifier" do
        activity_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <iati-activities generated-datetime="2019-09-25T22:01:44.470000+00:00" version="2.03">
            <!--Data generated by IATI CoVE. Built by Open Data Services Co-operative: http://iati.cove.opendataservices.coop/-->
            <iati-activity default-currency="GBP" hierarchy="2" last-updated-datetime="2019-09-25T22:01:44.470000+00:00">
              <iati-identifier>GB-GOV-13-GCRF-UKSA_NS_UKSA-019</iati-identifier>
            </iati-activity>
          </iati-activities>
        XML

        activity_node_set = Nokogiri::XML(activity_xml, nil, "UTF-8").xpath("//iati-activity").first

        result = described_class.new(activity_node_set: activity_node_set, delivery_partner: delivery_partner)

        expect(result.identifier).to eql("GB-GOV-13-GCRF-UKSA_NS_UKSA-019")
      end
    end

    context "when there is no identifier element" do
      it "returns nil" do
        activity_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <iati-activities generated-datetime="2019-09-25T22:01:44.470000+00:00" version="2.03">
            <!--Data generated by IATI CoVE. Built by Open Data Services Co-operative: http://iati.cove.opendataservices.coop/-->
            <iati-activity default-currency="GBP" hierarchy="2" last-updated-datetime="2019-09-25T22:01:44.470000+00:00">
            </iati-activity>
          </iati-activities>
        XML

        activity_node_set = Nokogiri::XML(activity_xml, nil, "UTF-8").xpath("//iati-activity").first

        result = described_class.new(activity_node_set: activity_node_set, delivery_partner: delivery_partner)

        expect(result.identifier).to eq(nil)
      end
    end
  end

  describe "#find_parent" do
    context "when the identifier matches to an activity" do
      it "returns the related activity" do
        existing_programme = create(:programme_activity, identifier: "GCRF-INTPART")

        fake_mapping = CSV::Table.new([
          CSV::Row.new([:activity_id, :parent_id], ["activity_id", "parent_id"]),
          CSV::Row.new([:activity_id, :parent_id], ["GB-GOV-13-GCRF-UKSA_CO_UKSA-34", "GCRF-INTPART"]),
        ])
        allow(CSV).to receive(:read).and_return(fake_mapping)

        iati_identifier = "GB-GOV-13-GCRF-UKSA_CO_UKSA-34"
        activity_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <iati-activities generated-datetime="2019-09-25T22:01:44.470000+00:00" version="2.03">
            <!--Data generated by IATI CoVE. Built by Open Data Services Co-operative: http://iati.cove.opendataservices.coop/-->
            <iati-activity default-currency="GBP" hierarchy="2" last-updated-datetime="2019-09-25T22:01:44.470000+00:00">
              <iati-identifier>#{iati_identifier}</iati-identifier>
            </iati-activity>
          </iati-activities>
        XML

        activity_node_set = Nokogiri::XML(activity_xml, nil, "UTF-8").xpath("//iati-activity").first

        legacy_activity = described_class.new(activity_node_set: activity_node_set, delivery_partner: delivery_partner)
        result = legacy_activity.find_parent

        expect(result).to eq(existing_programme)
      end
    end

    context "when the identifier cannot be matched to a programme" do
      it "raises a meaningful error" do
        fake_mapping = CSV::Table.new([
          CSV::Row.new([:project_id, :programme_id], ["project_id", "programme_id"]),
          CSV::Row.new([:project_id, :programme_id], ["GB-GOV-13-GCRF-UKSA_CO_UKSA-34", "GCRF-INTPART"]),
        ])
        allow(CSV).to receive(:read).and_return(fake_mapping)

        iati_identifier = "unexpected-activity-identifier"
        activity_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <iati-activities generated-datetime="2019-09-25T22:01:44.470000+00:00" version="2.03">
            <!--Data generated by IATI CoVE. Built by Open Data Services Co-operative: http://iati.cove.opendataservices.coop/-->
            <iati-activity default-currency="GBP" hierarchy="2" last-updated-datetime="2019-09-25T22:01:44.470000+00:00">
              <iati-identifier>#{iati_identifier}</iati-identifier>
            </iati-activity>
          </iati-activities>
        XML

        activity_node_set = Nokogiri::XML(activity_xml, nil, "UTF-8").xpath("//iati-activity").first

        legacy_activity = described_class.new(activity_node_set: activity_node_set, delivery_partner: delivery_partner)

        expect { legacy_activity.find_parent }.to raise_error(ParentNotFoundForActivity, iati_identifier)
      end
    end

    context "when this delivery partner does not have a mapping file" do
      it "raise a meaningful error" do
        # Stub for opening the mapping csv omitted to create a failing state

        delivery_partner = create(:delivery_partner_organisation,
          iati_reference: "GB-GOV-13-GCRF-SOMETHING_THAT_DOES_NOT_MATCH_A_FILE_NAME")

        iati_identifier = "GB-GOV-13-GCRF-MO-019"
        activity_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <iati-activities generated-datetime="2019-09-25T22:01:44.470000+00:00" version="2.03">
            <!--Data generated by IATI CoVE. Built by Open Data Services Co-operative: http://iati.cove.opendataservices.coop/-->
            <iati-activity default-currency="GBP" hierarchy="2" last-updated-datetime="2019-09-25T22:01:44.470000+00:00">
              <iati-identifier>#{iati_identifier}</iati-identifier>
            </iati-activity>
          </iati-activities>
        XML

        activity_node_set = Nokogiri::XML(activity_xml, nil, "UTF-8").xpath("//iati-activity").first

        legacy_activity = described_class.new(activity_node_set: activity_node_set, delivery_partner: delivery_partner)

        expect { legacy_activity.find_parent }.to raise_error(MissingMappingFileForOrganisation, delivery_partner.iati_reference)
      end
    end
  end

  describe "#infer_internal_identifier" do
    context "when the identifier is for a BEIS GCRF activity" do
      it "strips the BEIS and fund information from the reference" do
        iati_identifier = "GB-GOV-13-GCRF-UKSA_NS_UKSA-019"
        activity_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <iati-activities generated-datetime="2019-09-25T22:01:44.470000+00:00" version="2.03">
            <!--Data generated by IATI CoVE. Built by Open Data Services Co-operative: http://iati.cove.opendataservices.coop/-->
            <iati-activity default-currency="GBP" hierarchy="2" last-updated-datetime="2019-09-25T22:01:44.470000+00:00">
              <iati-identifier>#{iati_identifier}</iati-identifier>
            </iati-activity>
          </iati-activities>
        XML

        activity_node_set = Nokogiri::XML(activity_xml, nil, "UTF-8").xpath("//iati-activity").first

        legacy_activity = described_class.new(activity_node_set: activity_node_set, delivery_partner: delivery_partner)

        expect(legacy_activity.infer_internal_identifier).to eql("UKSA_NS_UKSA-019")
      end
    end

    context "when the identifier is for a BEIS Newton activity" do
      it "strips the BEIS and fund information from the identifier" do
        iati_identifier = "GB-GOV-13-NEWT-M0-019"
        activity_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <iati-activities generated-datetime="2019-09-25T22:01:44.470000+00:00" version="2.03">
            <!--Data generated by IATI CoVE. Built by Open Data Services Co-operative: http://iati.cove.opendataservices.coop/-->
            <iati-activity default-currency="GBP" hierarchy="2" last-updated-datetime="2019-09-25T22:01:44.470000+00:00">
              <iati-identifier>#{iati_identifier}</iati-identifier>
            </iati-activity>
          </iati-activities>
        XML

        activity_node_set = Nokogiri::XML(activity_xml, nil, "UTF-8").xpath("//iati-activity").first

        legacy_activity = described_class.new(activity_node_set: activity_node_set, delivery_partner: delivery_partner)

        expect(legacy_activity.infer_internal_identifier).to eql("M0-019")
      end
    end

    context "when the identifier is neither for a BEIS Newton nor a BEIS GCRF activity" do
      it "returns a valid identifier" do
        iati_identifier = "GB-GOV-13-S2-076"
        activity_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <iati-activities generated-datetime="2019-09-25T22:01:44.470000+00:00" version="2.03">
            <!--Data generated by IATI CoVE. Built by Open Data Services Co-operative: http://iati.cove.opendataservices.coop/-->
            <iati-activity default-currency="GBP" hierarchy="2" last-updated-datetime="2019-09-25T22:01:44.470000+00:00">
              <iati-identifier>#{iati_identifier}</iati-identifier>
            </iati-activity>
          </iati-activities>
        XML

        activity_node_set = Nokogiri::XML(activity_xml, nil, "UTF-8").xpath("//iati-activity").first

        legacy_activity = described_class.new(activity_node_set: activity_node_set, delivery_partner: delivery_partner)

        expect(legacy_activity.infer_internal_identifier).to eql("S2-076")
      end
    end
  end
end
