require "rails_helper"

RSpec.describe Activities::ImportFromCsv do
  let(:organisation) { create(:organisation) }
  let(:parent_activity) { create(:activity) }
  let(:existing_activity) { create(:activity) }
  let(:existing_activity_attributes) do
    {
      "RODA ID" => existing_activity.roda_identifier_compound,
      "Transparency identifier" => "13232332323",
      "RODA ID Fragment" => "",
      "Parent RODA ID" => "",
      "Title" => "Here is a title",
      "Description" => "Some description goes here...",
      "Recipient Region" => "789",
      "Recipient Country" => "KH",
      "Intended Beneficiaries" => "KH;KP;ID",
      "Delivery partner identifier" => "1234567890",
      "GDI" => "1",
      "SDG 1" => "1",
      "SDG 2" => "2",
      "SDG 3" => "3",
      "Covid-19 related research" => "0",
      "ODA Eligibility" => "never_eligible",
      "Programme Status" => "01",
      "Call open date" => "2020-01-02",
      "Call close date" => "2020-01-02",
      "Total applications" => "12",
      "Total awards" => "12",
      "Planned start date" => "2020-01-02",
      "Actual start date" => "2020-01-03",
      "Planned end date" => "2020-01-04",
      "Actual end date" => "2020-01-05",
      "Sector" => "11220",
      "Collaboration type (Bi/Multi Marker)" => "1",
    }
  end
  let(:new_activity_attributes) do
    {
      "RODA ID" => "",
      "Transparency identifier" => "3232332323",
      "RODA ID Fragment" => "234566",
      "Parent RODA ID" => parent_activity.roda_identifier_fragment,
      "Title" => "Here is a title",
      "Description" => "Some description goes here...",
      "Recipient Region" => "789",
      "Recipient Country" => "KH",
      "Intended Beneficiaries" => "KH;KP;ID",
      "Delivery partner identifier" => "98765432",
      "GDI" => "1",
      "SDG 1" => "1",
      "SDG 2" => "2",
      "SDG 3" => "3",
      "Covid-19 related research" => "0",
      "ODA Eligibility" => "never_eligible",
      "Programme Status" => "01",
      "Call open date" => "2020-01-02",
      "Call close date" => "2020-01-02",
      "Total applications" => "12",
      "Total awards" => "12",
      "Planned start date" => "2020-01-02",
      "Actual start date" => "2020-01-03",
      "Planned end date" => "2020-01-04",
      "Actual end date" => "2020-01-05",
      "Sector" => "11220",
      "Collaboration type (Bi/Multi Marker)" => "1",
    }
  end

  subject { described_class.new(organisation: organisation) }

  context "when updating an existing activity" do
    it "has an error if an Activity does not exist" do
      existing_activity_attributes["RODA ID"] = "FAKE RODA ID"

      expect { subject.import([existing_activity_attributes]) }.to_not change { existing_activity }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)

      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:roda_id)
      expect(subject.errors.first.value).to eq("FAKE RODA ID")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.not_found"))
    end

    it "has an error when the ID present, but there is a fragment present" do
      existing_activity_attributes["RODA ID Fragment"] = "13344"

      expect { subject.import([existing_activity_attributes]) }.to_not change { existing_activity }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:roda_identifier_fragment)
      expect(subject.errors.first.value).to eq("13344")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.cannot_update.fragment_present"))
    end

    it "has an error when the ID present, but there is a parent present" do
      existing_activity_attributes["Parent RODA ID"] = parent_activity.roda_identifier_fragment

      expect { subject.import([existing_activity_attributes]) }.to_not change { existing_activity }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:parent_id)
      expect(subject.errors.first.value).to eq(parent_activity.roda_identifier_fragment)
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.cannot_update.parent_present"))
    end

    it "updates an existing activity" do
      subject.import([existing_activity_attributes])

      expect(subject.errors.count).to eq(0)
      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(1)

      expect(existing_activity.reload.transparency_identifier).to eq(existing_activity_attributes["Transparency identifier"])
      expect(existing_activity.title).to eq(existing_activity_attributes["Title"])
      expect(existing_activity.description).to eq(existing_activity_attributes["Description"])
      expect(existing_activity.recipient_region).to eq(existing_activity_attributes["Recipient Region"])
      expect(existing_activity.recipient_country).to eq(existing_activity_attributes["Recipient Country"])
      expect(existing_activity.intended_beneficiaries).to eq(["KH", "KP", "ID"])
      expect(existing_activity.gdi).to eq("1")
      expect(existing_activity.delivery_partner_identifier).to eq(existing_activity_attributes["Delivery partner identifier"])
      expect(existing_activity.covid19_related).to eq(0)
      expect(existing_activity.oda_eligibility).to eq("never_eligible")
      expect(existing_activity.programme_status).to eq("01")
      expect(existing_activity.call_open_date).to eq(DateTime.parse(existing_activity_attributes["Call open date"]))
      expect(existing_activity.call_close_date).to eq(DateTime.parse(existing_activity_attributes["Call close date"]))
      expect(existing_activity.planned_start_date).to eq(DateTime.parse(existing_activity_attributes["Planned start date"]))
      expect(existing_activity.planned_end_date).to eq(DateTime.parse(existing_activity_attributes["Planned end date"]))
      expect(existing_activity.actual_start_date).to eq(DateTime.parse(existing_activity_attributes["Actual start date"]))
      expect(existing_activity.actual_end_date).to eq(DateTime.parse(existing_activity_attributes["Actual end date"]))
      expect(existing_activity.call_present).to eq(true)
      expect(existing_activity.sector).to eq(existing_activity_attributes["Sector"])
      expect(existing_activity.sector_category).to eq("112")
      expect(existing_activity.collaboration_type).to eq(existing_activity_attributes["Collaboration type (Bi/Multi Marker)"])
    end

    it "ignores any blank columns" do
      existing_activity_attributes["Title"] = ""

      expect { subject.import([existing_activity_attributes]) }.to_not change { existing_activity.title }
      expect(subject.errors.count).to eq(0)
    end

    it "has an error and does not update any other activities if an Activity does not exist" do
      activities = [
        existing_activity_attributes,
        {
          "RODA ID" => "FAKE RODA ID",
          "Title" => "Here is another title",
          "Description" => "Another description goes here...",
          "Recipient Region" => "789",
        },
      ]

      expect { subject.import(activities) }.to_not change { existing_activity }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(3)
      expect(subject.errors.first.column).to eq(:roda_id)
      expect(subject.errors.first.value).to eq("FAKE RODA ID")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.not_found"))
    end

    it "has an error and does not update any other activities if a region does not exist" do
      activity_2 = create(:activity)

      activities = [
        existing_activity_attributes,
        {
          "RODA ID" => activity_2.roda_identifier_compound,
          "Title" => "Here is another title",
          "Description" => "Another description goes here...",
          "Recipient Region" => "111111",
        },
      ]

      expect { subject.import(activities) }.to_not change { existing_activity }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(3)
      expect(subject.errors.first.column).to eq(:recipient_region)
      expect(subject.errors.first.value).to eq("111111")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_region"))
    end
  end

  context "when creating a new activity" do
    it "returns an error when the ID and fragments are not present" do
      existing_activity_attributes["RODA ID"] = ""

      expect { subject.import([existing_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:roda_id)
      expect(subject.errors.first.value).to eq("")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.cannot_create"))
    end

    it "creates the activity" do
      rows = [new_activity_attributes]
      expect { subject.import(rows) }.to change { Activity.count }.by(1)

      expect(subject.created.count).to eq(1)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(0)

      new_activity = Activity.order(:created_at).last

      expected_roda_identifier_compound = [
        parent_activity.roda_identifier_compound,
        new_activity_attributes["RODA ID Fragment"],
      ].join("-")

      expect(new_activity.parent).to eq(parent_activity)
      expect(new_activity.roda_identifier_compound).to eq(expected_roda_identifier_compound)
      expect(new_activity.transparency_identifier).to eq(new_activity_attributes["Transparency identifier"])
      expect(new_activity.title).to eq(new_activity_attributes["Title"])
      expect(new_activity.description).to eq(new_activity_attributes["Description"])
      expect(new_activity.roda_identifier_fragment).to eq(new_activity_attributes["RODA ID Fragment"])
      expect(new_activity.recipient_region).to eq(new_activity_attributes["Recipient Region"])
      expect(new_activity.recipient_country).to eq(new_activity_attributes["Recipient Country"])
      expect(new_activity.intended_beneficiaries).to eq(["KH", "KP", "ID"])
      expect(new_activity.gdi).to eq("1")
      expect(new_activity.geography).to eq("recipient_region")
      expect(new_activity.delivery_partner_identifier).to eq(new_activity_attributes["Delivery partner identifier"])
      expect(new_activity.covid19_related).to eq(0)
      expect(new_activity.oda_eligibility).to eq("never_eligible")
      expect(new_activity.programme_status).to eq("01")
      expect(new_activity.call_open_date).to eq(DateTime.parse(new_activity_attributes["Call open date"]))
      expect(new_activity.call_close_date).to eq(DateTime.parse(new_activity_attributes["Call close date"]))
      expect(new_activity.call_present).to eq(true)
      expect(new_activity.planned_start_date).to eq(DateTime.parse(new_activity_attributes["Planned start date"]))
      expect(new_activity.planned_end_date).to eq(DateTime.parse(new_activity_attributes["Planned end date"]))
      expect(new_activity.actual_start_date).to eq(DateTime.parse(new_activity_attributes["Actual start date"]))
      expect(new_activity.actual_end_date).to eq(DateTime.parse(new_activity_attributes["Actual end date"]))
      expect(new_activity.sector).to eq(new_activity_attributes["Sector"])
      expect(new_activity.sector_category).to eq("112")
      expect(new_activity.collaboration_type).to eq(new_activity_attributes["Collaboration type (Bi/Multi Marker)"])
    end

    it "sets the geography to recipient country and infers the region if the region is not specified" do
      new_activity_attributes["Recipient Region"] = ""

      expect { subject.import([new_activity_attributes]) }.to change { Activity.count }

      new_activity = Activity.order(:created_at).last

      expect(new_activity.geography).to eq("recipient_country")
      expect(new_activity.recipient_region).to eq("789")
    end

    it "allows the Call Open and Close Dates to be blank" do
      new_activity_attributes["Call open date"] = ""
      new_activity_attributes["Call close date"] = ""

      expect { subject.import([new_activity_attributes]) }.to change { Activity.count }

      new_activity = Activity.order(:created_at).last

      expect(new_activity.call_open_date).to be_nil
      expect(new_activity.call_close_date).to be_nil
      expect(new_activity.call_present).to eq(false)
    end

    it "has an error if a region does not exist" do
      new_activity_attributes["Recipient Region"] = "111111"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:recipient_region)
      expect(subject.errors.first.value).to eq("111111")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_region"))
    end

    it "has an error if a country does not exist" do
      new_activity_attributes["Recipient Country"] = "BBBBBB"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:recipient_country)
      expect(subject.errors.first.value).to eq("BBBBBB")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_country"))
    end

    it "has an error if the intended beneficiaries are invalid" do
      new_activity_attributes["Intended Beneficiaries"] = "ffsdfdsfsfds"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:intended_beneficiaries)
      expect(subject.errors.first.value).to eq("ffsdfdsfsfds")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_intended_beneficiaries"))
    end

    it "has an error if the GDI is invalid" do
      new_activity_attributes["GDI"] = "2222222"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:gdi)
      expect(subject.errors.first.value).to eq("2222222")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_gdi"))
    end

    ["SDG 1", "SDG 2", "SDG 3"].each.with_index(1) do |key, i|
      it "has an error if the #{i.ordinalize} sustainable development goal is invalid" do
        new_activity_attributes[key] = "9999999"

        expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.column).to eq("sdg_#{i}".to_sym)
        expect(subject.errors.first.value).to eq("9999999")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_sdg_goal"))
      end
    end

    it "has an error if the Covid-19 related option is invalid" do
      new_activity_attributes["Covid-19 related research"] = "9999999"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:covid19_related)
      expect(subject.errors.first.value).to eq("9999999")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_covid19_related"))
    end

    it "has an error if the ODA Eligibility option is invalid" do
      new_activity_attributes["ODA Eligibility"] = "some_invalid_string"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:oda_eligibility)
      expect(subject.errors.first.value).to eq("some_invalid_string")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_oda_eligibility"))
    end

    it "has an error if the Programme Status option is invalid" do
      new_activity_attributes["Programme Status"] = "99331"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:programme_status)
      expect(subject.errors.first.value).to eq("99331")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_programme_status"))
    end

    it "has an error if the Sector option is invalid" do
      new_activity_attributes["Sector"] = "53453453453453"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:sector)
      expect(subject.errors.first.value).to eq("53453453453453")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_sector"))
    end

    it "has an error if the Collaboration type option is invalid" do
      new_activity_attributes["Collaboration type (Bi/Multi Marker)"] = "99"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:collaboration_type)
      expect(subject.errors.first.value).to eq("99")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_collaboration_type"))
    end

    {
      "Call open date" => :call_open_date,
      "Call close date" => :call_close_date,
      "Planned start date" => :planned_start_date,
      "Planned end date" => :planned_end_date,
      "Actual start date" => :actual_start_date,
      "Actual end date" => :actual_end_date,
    }.each do |attr_name, column_name|
      it "has an error if any the #{attr_name} is invalid" do
        new_activity_attributes[attr_name] = "01/01/2020"

        expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.column).to eq(column_name)
        expect(subject.errors.first.value).to eq("01/01/2020")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_#{column_name}"))
      end
    end

    it "has an error if the parent activity cannot be found" do
      new_activity_attributes["Parent RODA ID"] = "111111"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:parent_id)
      expect(subject.errors.first.value).to eq("111111")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.parent_not_found"))
    end

    it "has an error if the identifier is invalid" do
      new_activity_attributes["RODA ID Fragment"] = "%^$!234566"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:roda_identifier_fragment)
      expect(subject.errors.first.value).to eq("%^$!234566")
      expect(subject.errors.first.message).to eq(I18n.t("activerecord.errors.models.activity.attributes.roda_identifier_fragment.invalid_characters"))
    end
  end

  context "when updating and importing" do
    it "creates and imports activities" do
      rows = [existing_activity_attributes, new_activity_attributes]
      expect { subject.import(rows) }.to change { Activity.count }.by(1)

      expect(subject.created.count).to eq(1)
      expect(subject.updated.count).to eq(1)

      expect(subject.errors.count).to eq(0)
    end
  end
end
