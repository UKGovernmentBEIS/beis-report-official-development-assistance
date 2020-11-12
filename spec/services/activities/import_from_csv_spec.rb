require "rails_helper"

RSpec.describe Activities::ImportFromCsv do
  let(:organisation) { create(:organisation) }
  let(:existing_activity) { create(:activity) }
  let(:activity_attributes) do
    {
      "RODA ID" => existing_activity.roda_identifier_compound,
      "Title" => "Here is a title",
      "Description" => "Some description goes here...",
      "Recipient Region" => "789",
      "Delivery partner identifier" => "1234567890",
    }
  end

  subject { described_class.new(organisation: organisation) }

  it "returns an error when the RODA ID is not present" do
    activity_attributes["RODA ID"] = ""
    expect { subject.import([activity_attributes]) }.to_not change { Activity.count }

    expect(subject.errors.count).to eq(1)

    expect(subject.errors.first.csv_row).to eq(2)
    expect(subject.errors.first.column).to eq(:roda_id)
    expect(subject.errors.first.value).to eq("")
    expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.cannot_update"))
  end

  context "when updating an existing activity" do
    it "has an error if an Activity does not exist" do
      activity_attributes["RODA ID"] = "FAKE RODA ID"

      subject.import([activity_attributes])

      expect(subject.errors.count).to eq(1)

      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.column).to eq(:roda_id)
      expect(subject.errors.first.value).to eq("FAKE RODA ID")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.not_found"))
    end

    it "updates an existing activity" do
      subject.import([activity_attributes])

      expect(subject.errors.count).to eq(0)

      expect(existing_activity.reload.title).to eq(activity_attributes["Title"])
      expect(existing_activity.description).to eq(activity_attributes["Description"])
      expect(existing_activity.recipient_region).to eq(activity_attributes["Recipient Region"])
      expect(existing_activity.delivery_partner_identifier).to eq(activity_attributes["Delivery partner identifier"])
    end

    it "ignores any blank columns" do
      activity_attributes["Title"] = ""

      expect { subject.import([activity_attributes]) }.to_not change { existing_activity.title }
      expect(subject.errors.count).to eq(0)
    end

    it "has an error and does not update any other activities if an Activity does not exist" do
      activities = [
        activity_attributes,
        {
          "RODA ID" => "FAKE RODA ID",
          "Title" => "Here is another title",
          "Description" => "Another description goes here...",
          "Recipient Region" => "789",
        },
      ]

      expect { subject.import(activities) }.to_not change { existing_activity }

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(3)
      expect(subject.errors.first.column).to eq(:roda_id)
      expect(subject.errors.first.value).to eq("FAKE RODA ID")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.not_found"))
    end

    it "has an error and does not update any other activities if a region does not exist" do
      activity_2 = create(:activity)

      activities = [
        activity_attributes,
        {
          "RODA ID" => activity_2.roda_identifier_compound,
          "Title" => "Here is another title",
          "Description" => "Another description goes here...",
          "Recipient Region" => "111111",
        },
      ]

      expect { subject.import(activities) }.to_not change { existing_activity }

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(3)
      expect(subject.errors.first.column).to eq(:recipient_region)
      expect(subject.errors.first.value).to eq("111111")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_region"))
    end
  end
end
