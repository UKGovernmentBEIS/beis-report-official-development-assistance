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
      "Recipient Country" => "LR",
      "Delivery partner identifier" => "1234567890",
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
      "Recipient Country" => "LR",
      "Delivery partner identifier" => "98765432",
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
      expect(existing_activity.delivery_partner_identifier).to eq(existing_activity_attributes["Delivery partner identifier"])
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
      expect(new_activity.geography).to eq("recipient_region")
      expect(new_activity.delivery_partner_identifier).to eq(new_activity_attributes["Delivery partner identifier"])
    end

    it "sets the geography to recipient country if the region is not specified" do
      new_activity_attributes["Recipient Region"] = ""

      subject.import([new_activity_attributes])

      new_activity = Activity.order(:created_at).last

      expect(new_activity.geography).to eq("recipient_country")
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
