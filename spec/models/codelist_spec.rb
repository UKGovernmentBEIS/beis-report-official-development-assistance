require "rails_helper"

RSpec.describe Codelist do
  it "initializes an IATI codelist correctly" do
    codelist = Codelist.new(type: "default_currency")
    expect(codelist.count).to eq(169)
  end

  it "initializes a BEIS codelist correctly" do
    codelist = Codelist.new(type: "fund_pillar", source: "beis")
    expect(codelist.count).to eq(4)
  end

  it "raises an error when the source is incorrect" do
    expect { Codelist.new(type: "favourite_colours", source: "colours") }.to raise_error "Codelist::UnrecognisedSource"
  end

  it "raises an error when the codelist is missing or incorrect" do
    expect { Codelist.new(type: "favourite_colours") }.to raise_error "Codelist::UnreadableCodelist"
  end

  context "in production" do
    before { allow(Rails).to receive(:env) { "production".inquiry } }

    it "does not reinitialize the codelist once it has been initialized" do
      expect(Codelist).to receive(:initialize_codelists).once.and_call_original

      Codelist.new(type: "default_currency")
      Codelist.new(type: "fund_pillar", source: "beis")
    end
  end

  context "in development" do
    before { allow(Rails).to receive(:env) { "development".inquiry } }

    it "reloads the codelist every time" do
      expect(Codelist).to receive(:initialize_codelists).twice.and_call_original

      Codelist.new(type: "default_currency")
      Codelist.new(type: "fund_pillar", source: "beis")
    end
  end

  describe "to_objects" do
    it "formats the data from a codelist to an array of objects for use in govuk form builder" do
      expect(Codelist.new(type: "default_currency").to_objects)
        .to include(
          OpenStruct.new(name: "Afghani", code: "AFN"),
          OpenStruct.new(name: "Lek", code: "ALL"),
          OpenStruct.new(name: "Armenian Dram", code: "AMD"),
          OpenStruct.new(name: "Netherlands Antillian Guilder", code: "ANG"),
          OpenStruct.new(name: "Kwanza", code: "AOA")
        )
    end

    it "adds a blank first item by default" do
      expect(
        Codelist.new(type: "default_currency").to_objects.first
      ).to eq(OpenStruct.new(name: "", code: ""))
    end

    it "removes the blank first item if you need it to" do
      expect(
        Codelist.new(type: "default_currency").to_objects(with_empty_item: false).first
      ).to_not eq(OpenStruct.new(name: "", code: ""))
    end

    it "sorts the resulting objects by name order" do
      codelist = Codelist.new(type: "default_currency")
      objects = codelist.to_objects(with_empty_item: false)

      expect(objects.first).to eq(OpenStruct.new(name: "Afghani", code: "AFN"))
      expect(objects.last).to eq(OpenStruct.new(name: "Zloty", code: "PLN"))
    end

    context "when there are three 'withdrawn' items and one 'active' item" do
      let(:fake_yaml) { YAML.safe_load(File.read("#{Rails.root}/spec/fixtures/codelist_with_withdrawn_items.yml")) }
      let(:codelist) { Codelist.new(type: "sector") }

      before do
        allow(codelist).to receive(:list).and_return(fake_yaml["data"])
      end

      it "only adds the 'active' item to the final list" do
        list = codelist.to_objects(
          with_empty_item: false
        )

        expect(list.count).to eq(1)
        expect(list.first.name).to eq("Active code")
      end
    end

    it "does not add any duplicate-named items to the list" do
      list = Codelist.new(type: "sector").to_objects(
        with_empty_item: false
      )
      grouped_by_name = list.group_by { |item| item["name"] }
      duplicate_groups = grouped_by_name.values.select { |a| a.size > 1 }.flatten
      expect(duplicate_groups.count).to eql(0)
    end
  end

  describe "#to_objects_with_description" do
    it "formats the data from a codelist to an array of objects for use in govuk form builder, with descriptions" do
      expect(Codelist.new(type: "status").to_objects_with_description)
        .to include(
          OpenStruct.new(name: "Pipeline/identification", code: "1", description: "The activity is being scoped or planned"),
          OpenStruct.new(name: "Implementation", code: "2", description: "The activity is currently being implemented"),
          OpenStruct.new(name: "Completion", code: "3", description: "Physical activity is complete or the final disbursement has been made"),
          OpenStruct.new(name: "Post-completion", code: "4", description: "Physical activity is complete or the final disbursement has been made, but the activity remains open pending financial sign off or M&E"),
          OpenStruct.new(name: "Cancelled", code: "5", description: "The activity has been cancelled"),
          OpenStruct.new(name: "Suspended", code: "6", description: "The activity has been temporarily suspended")
        )
    end

    it "sorts the data by code order" do
      expect(Codelist.new(type: "status").to_objects_with_description.first).to eq(OpenStruct.new(name: "Pipeline/identification", code: "1", description: "The activity is being scoped or planned"))
      expect(Codelist.new(type: "status").to_objects_with_description.last).to eq(OpenStruct.new(name: "Suspended", code: "6", description: "The activity has been temporarily suspended"))
    end

    it "tries to get a description from the translations if one is available" do
      objects = Codelist.new(type: "aid_type").to_objects_with_description(type: "aid_type")

      expect(objects.find { |o| o["code"] == "B02" }.description).to eq(t("form.hint.activity.options.aid_type.B02"))
      expect(objects.find { |o| o["code"] == "E01" }.description).to eq("Financial aid awards for individual students and contributions to trainees.")
    end
  end

  describe "#values_for" do
    let(:codelist) { Codelist.new(type: "aid_type") }

    it "fetches the values with a particular key from a codelist" do
      expect(codelist.values_for("code")).to eq(["A01", "A02", "B01", "B02", "B03", "B04", "C01", "D01", "D02", "E01", "E02", "F01", "G01", "H01", "H02"])
    end

    it "raises an error if the key does not exist" do
      expect { codelist.values_for("words") }.to raise_error "Codelist::KeyNotFound"
    end
  end
end
