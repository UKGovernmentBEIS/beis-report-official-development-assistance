require "rails_helper"

RSpec.describe Activity::Import do
  let(:organisation) { create(:partner_organisation) }
  let(:uploader) { create(:beis_user) }

  let(:generic_level_b_activity_attributes) do
    {
      "Transparency identifier" => "13232332323",
      "Parent RODA ID" => "",
      "Title" => "Here is a title",
      "Description" => "Some description goes here...",
      "Benefitting Countries" => "KH|KP|ID",
      "GDI" => "1",
      "SDG 1" => "1",
      "SDG 2" => "2",
      "SDG 3" => "3",
      "Covid-19 related research" => "0",
      "ODA Eligibility" => "0",
      "Activity Status" => "1",
      "Planned start date" => "02/01/2020",
      "Actual start date" => "03/01/2020",
      "Planned end date" => "04/01/2020",
      "Actual end date" => "05/01/2020",
      "Sector" => "11220",
      "Collaboration type (Bi/Multi Marker)" => "1",
      "Aid type" => "B03",
      "Free Standing Technical Cooperation" => "1",
      "Aims/Objectives" => "Foo bar baz",
      "UK PO Named Contact" => "Jo Soap"
    }
  end

  context "Importing fields that span multiple types of activity" do
    let(:fund_activity) { create(:fund_activity, :newton) }

    let!(:existing_newton_level_b_activity) do
      create(:programme_activity, :newton_funded, extending_organisation: organisation) do |activity|
        activity.implementing_organisations = [organisation]
      end
    end

    let(:existing_newton_level_b_activity_attributes) {
      generic_level_b_activity_attributes.merge({
        "RODA ID" => existing_newton_level_b_activity.roda_identifier,
        "Newton Fund Pillar" => "1",
        "NF Partner Country PO" => "Association of Example Companies (AEC) | | Board of Sample Organisations (BSO)"
      })
    }

    let(:new_newton_activity_attributes) do
      existing_newton_level_b_activity_attributes.merge({
        "RODA ID" => "",
        "Parent RODA ID" => fund_activity.roda_identifier,
        "Transparency identifier" => "23232332323",
        "Partner organisation identifier" => "9876543210"
      })
    end

    subject { described_class.new(uploader: uploader, partner_organisation: organisation, report: nil, is_oda: nil) }

    context "when updating an existing activity" do
      let(:activity_policy_double) { instance_double("ActivityPolicy", update?: true) }

      before do
        allow(ActivityPolicy).to receive(:new).and_return(activity_policy_double)
      end

      it "has an error if an Activity does not exist" do
        existing_newton_level_b_activity_attributes["RODA ID"] = "FAKE RODA ID"

        expect { subject.import([existing_newton_level_b_activity_attributes]) }.to_not change { existing_newton_level_b_activity }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)

        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("RODA ID")
        expect(subject.errors.first.attribute_name).to eq(:roda_identifier)
        expect(subject.errors.first.value).to eq("FAKE RODA ID")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.not_found"))
      end

      it "has an error when both the ID and Parent ID are present, as this may overwrite the existing Parent ID" do
        existing_newton_level_b_activity_attributes["Parent RODA ID"] = existing_newton_level_b_activity.roda_identifier

        expect { subject.import([existing_newton_level_b_activity_attributes]) }.to_not change { existing_newton_level_b_activity }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Parent RODA ID")
        expect(subject.errors.first.attribute_name).to eq(:parent_id)
        expect(subject.errors.first.value).to eq(existing_newton_level_b_activity.roda_identifier)
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.cannot_update.parent_present"))
      end

      it "updates an existing activity" do
        subject.import([existing_newton_level_b_activity_attributes])

        expect(subject.errors.count).to eq(0)
        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(1)

        expect(existing_newton_level_b_activity.reload.transparency_identifier).to eq(existing_newton_level_b_activity_attributes["Transparency identifier"])
        expect(existing_newton_level_b_activity.title).to eq(existing_newton_level_b_activity_attributes["Title"])
        expect(existing_newton_level_b_activity.description).to eq(existing_newton_level_b_activity_attributes["Description"])
        expect(existing_newton_level_b_activity.gdi).to eq("1")
        expect(existing_newton_level_b_activity.fund_pillar).to eq(existing_newton_level_b_activity_attributes["Newton Fund Pillar"].to_i)
        expect(existing_newton_level_b_activity.covid19_related).to eq(0)
        expect(existing_newton_level_b_activity.oda_eligibility).to eq("never_eligible")
        expect(existing_newton_level_b_activity.programme_status).to eq("delivery")
        expect(existing_newton_level_b_activity.iati_status).to eq("2")
        expect(existing_newton_level_b_activity.planned_start_date).to eq(DateTime.parse(existing_newton_level_b_activity_attributes["Planned start date"]))
        expect(existing_newton_level_b_activity.planned_end_date).to eq(DateTime.parse(existing_newton_level_b_activity_attributes["Planned end date"]))
        expect(existing_newton_level_b_activity.actual_start_date).to eq(DateTime.parse(existing_newton_level_b_activity_attributes["Actual start date"]))
        expect(existing_newton_level_b_activity.actual_end_date).to eq(DateTime.parse(existing_newton_level_b_activity_attributes["Actual end date"]))
        expect(existing_newton_level_b_activity.sector).to eq(existing_newton_level_b_activity_attributes["Sector"])
        expect(existing_newton_level_b_activity.sector_category).to eq("112")
        expect(existing_newton_level_b_activity.collaboration_type).to eq(existing_newton_level_b_activity_attributes["Collaboration type (Bi/Multi Marker)"])
        expect(existing_newton_level_b_activity.aid_type).to eq(existing_newton_level_b_activity_attributes["Aid type"])
        expect(existing_newton_level_b_activity.fstc_applies).to be(true)
        expect(existing_newton_level_b_activity.objectives).to eq(existing_newton_level_b_activity_attributes["Aims/Objectives"])
        expect(existing_newton_level_b_activity.beis_identifier).to eq(existing_newton_level_b_activity_attributes["BEIS ID"])
        expect(existing_newton_level_b_activity.uk_po_named_contact).to eq(existing_newton_level_b_activity_attributes["UK PO Named Contact"])
        expect(existing_newton_level_b_activity.sdgs_apply).to be(true)
        expect(existing_newton_level_b_activity.country_partner_organisations).to eq(["Association of Example Companies (AEC)", "Board of Sample Organisations (BSO)"])
        expect(existing_newton_level_b_activity.form_state).to eq "complete"
      end

      it "sets form_state to complete" do
        subject.import([existing_newton_level_b_activity_attributes])

        expect(existing_newton_level_b_activity.reload.form_state).to eq "complete"
      end

      it "ignores any blank columns" do
        existing_newton_level_b_activity_attributes["Title"] = ""

        expect { subject.import([existing_newton_level_b_activity_attributes]) }.to_not change { existing_newton_level_b_activity.title }
        expect(subject.errors.count).to eq(0)
      end

      it "has an error and does not update any other activities if an Activity does not exist" do
        invalid_activity_attributes = existing_newton_level_b_activity_attributes.merge({"RODA ID" => "FAKE RODA ID"})
        activities = [
          existing_newton_level_b_activity_attributes,
          invalid_activity_attributes
        ]
        expect { subject.import(activities) }.to_not change { existing_newton_level_b_activity }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)
        expect(subject.errors.count).to eq(1)
      end

      context "when carrying out a partial update" do
        let!(:old_activity_attributes) { existing_newton_level_b_activity.attributes }

        let(:attributes) do
          attributes = existing_newton_level_b_activity_attributes.map { |k, _v| [k, ""] }.to_h
          attributes["RODA ID"] = existing_newton_level_b_activity.roda_identifier
          attributes
        end
        let(:changed_attributes) do
          (existing_newton_level_b_activity.reload.attributes.to_a - old_activity_attributes.to_a).to_h.except("updated_at")
        end

        it "allows a partial update without a sector code" do
          attributes["Title"] = "New Title"
          attributes["Description"] = "Here is a description"

          subject.import([attributes])

          expect(subject.updated.count).to eq(1)

          expect(changed_attributes).to eq(
            "title" => "New Title",
            "description" => "Here is a description"
          )
        end

        it "has the expected errors if the activity is invalid" do
          existing_newton_level_b_activity.sector_category = nil
          existing_newton_level_b_activity.save(validate: false)

          attributes["Title"] = "New Title"

          subject.import([attributes])

          expect(subject.created.count).to eq(0)
          expect(subject.updated.count).to eq(0)
          expect(subject.errors.count).to eq(1)

          expect(subject.errors.first.message).to eq("Select a category")
        end
      end

      context "when you don't have permission to update the existing activities" do
        let(:activity_policy_double) { instance_double("ActivityPolicy", update?: false) }

        it "doesn't update the activity and reports the error" do
          subject.import([existing_newton_level_b_activity_attributes])
          expect(subject.updated.count).to eq(0)
          expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.unauthorised"))
        end
      end
    end

    context "when creating a new activity" do
      let(:activity_policy_double) { instance_double("ActivityPolicy", create_child?: true) }

      before do
        allow(ActivityPolicy).to receive(:new).with(uploader, fund_activity).and_return(activity_policy_double)
      end

      it "returns an error when the ID and fragments are not present" do
        existing_newton_level_b_activity_attributes["RODA ID"] = ""

        expect { subject.import([existing_newton_level_b_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("roda_id")
        expect(subject.errors.first.attribute_name).to eq(:roda_id)
        expect(subject.errors.first.value).to eq("")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.cannot_create"))
      end

      it "creates the activity" do
        rows = [new_newton_activity_attributes]
        expect { subject.import(rows) }.to change { Activity.count }.by(1)

        expect(subject.created.count).to eq(1)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(0)

        new_activity = Activity.order(:created_at).last

        expect(new_activity.parent).to eq(fund_activity)
        expect(new_activity.source_fund_code).to eq(1)
        expect(new_activity.level).to eq("programme")
        expect(new_activity.transparency_identifier).to eq(new_newton_activity_attributes["Transparency identifier"])
        expect(new_activity.title).to eq(new_newton_activity_attributes["Title"])
        expect(new_activity.description).to eq(new_newton_activity_attributes["Description"])
        expect(new_activity.benefitting_countries).to eq(["KH", "KP", "ID"])
        expect(new_activity.gdi).to eq("1")
        expect(new_activity.partner_organisation_identifier).to eq(new_newton_activity_attributes["Partner organisation identifier"])
        expect(new_activity.covid19_related).to eq(0)
        expect(new_activity.oda_eligibility).to eq("never_eligible")
        expect(new_activity.oda_eligibility_lead).to be_nil
        expect(new_activity.programme_status).to eq("delivery")
        expect(new_activity.iati_status).to eq("2")
        expect(new_activity.fund_pillar).to eq(new_newton_activity_attributes["Newton Fund Pillar"].to_i)
        expect(new_activity.call_open_date).to be_nil
        expect(new_activity.call_close_date).to be_nil
        expect(new_activity.call_present).to be(false)
        expect(new_activity.planned_start_date).to eq(DateTime.parse(new_newton_activity_attributes["Planned start date"]))
        expect(new_activity.planned_end_date).to eq(DateTime.parse(new_newton_activity_attributes["Planned end date"]))
        expect(new_activity.actual_start_date).to eq(DateTime.parse(new_newton_activity_attributes["Actual start date"]))
        expect(new_activity.actual_end_date).to eq(DateTime.parse(new_newton_activity_attributes["Actual end date"]))
        expect(new_activity.sector).to eq(new_newton_activity_attributes["Sector"])
        expect(new_activity.sector_category).to eq("112")
        expect(new_activity.collaboration_type).to eq(new_newton_activity_attributes["Collaboration type (Bi/Multi Marker)"])
        expect(new_activity.aid_type).to eq(new_newton_activity_attributes["Aid type"])
        expect(new_activity.fstc_applies).to be(true)
        expect(new_activity.objectives).to eq(new_newton_activity_attributes["Aims/Objectives"])
        expect(new_activity.beis_identifier).to eq("")
        expect(new_activity.uk_po_named_contact).to eq(new_newton_activity_attributes["UK PO Named Contact"])
        expect(new_activity.country_partner_organisations).to eq(["Association of Example Companies (AEC)", "Board of Sample Organisations (BSO)"])
        expect(new_activity.sdgs_apply).to be(true)
      end

      it "sets BEIS as the accountable organisation" do
        beis = create(:beis_organisation)

        subject.import([new_newton_activity_attributes])

        new_activity = Activity.order(:created_at).last
        expect(new_activity.accountable_organisation_name).to eq beis.name
        expect(new_activity.accountable_organisation_reference).to eq beis.iati_reference
        expect(new_activity.accountable_organisation_type).to eq beis.organisation_type
      end

      it "sets form_state to complete" do
        subject.import([new_newton_activity_attributes])

        new_activity = Activity.order(:created_at).last
        expect(new_activity.form_state).to eq "complete"
      end

      it "sets the partner organisation as the implementing organisation" do
        rows = [new_newton_activity_attributes]
        subject.import(rows)

        new_activity = Activity.order(:created_at).last

        expect(new_activity.implementing_organisations).to eq([organisation])
      end

      it "has an error if the benefitting countries are invalid" do
        new_newton_activity_attributes["Benefitting Countries"] = "ffsdfdsfsfds"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Benefitting Countries")
        expect(subject.errors.first.attribute_name).to eq(:benefitting_countries)
        expect(subject.errors.first.value).to eq("ffsdfdsfsfds")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_benefitting_countries"))
      end

      it "has an error if the benefitting countries are graduated or not from the list" do
        new_newton_activity_attributes["Benefitting Countries"] = ["UK", "SC"]

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.errors.first.csv_column_name).to eq("Benefitting Countries")
        expect(subject.errors.first.attribute_name).to eq(:benefitting_countries)
        expect(subject.errors.first.value).to include("UK")
        expect(subject.errors.first.value).to include("SC")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_benefitting_countries"))
      end

      it "has an error if the GDI is invalid" do
        new_newton_activity_attributes["GDI"] = "2222222"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("GDI")
        expect(subject.errors.first.attribute_name).to eq(:gdi)
        expect(subject.errors.first.value).to eq("2222222")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_gdi"))
      end

      it "sets the extending organisation" do
        subject.import([new_newton_activity_attributes])

        new_activity = Activity.order(:created_at).last
        expect(new_activity.extending_organisation).to eq(organisation)
      end

      ["SDG 1", "SDG 2", "SDG 3"].each.with_index(1) do |key, i|
        it "has an error if the #{i.ordinalize} sustainable development goal is invalid" do
          new_newton_activity_attributes[key] = "9999999"

          expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

          expect(subject.created.count).to eq(0)
          expect(subject.updated.count).to eq(0)

          expect(subject.errors.count).to eq(1)
          expect(subject.errors.first.csv_row).to eq(2)
          expect(subject.errors.first.csv_column_name).to eq("SDG #{i}")
          expect(subject.errors.first.attribute_name).to eq("sdg_#{i}".to_sym)
          expect(subject.errors.first.value).to eq("9999999")
          expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_sdg_goal"))
        end
      end

      it "has an error if the Fund Pillar option is invalid" do
        new_newton_activity_attributes["Newton Fund Pillar"] = "9999999"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Newton Fund Pillar")
        expect(subject.errors.first.attribute_name).to eq(:fund_pillar)
        expect(subject.errors.first.value).to eq("9999999")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_fund_pillar"))
      end

      it "has an error if the Covid-19 related option is invalid" do
        new_newton_activity_attributes["Covid-19 related research"] = "9999999"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Covid-19 related research")
        expect(subject.errors.first.attribute_name).to eq(:covid19_related)
        expect(subject.errors.first.value).to eq("9999999")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_covid19_related"))
      end

      it "has an error if the ODA Eligibility option is invalid" do
        new_newton_activity_attributes["ODA Eligibility"] = "789"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("ODA Eligibility")
        expect(subject.errors.first.attribute_name).to eq(:oda_eligibility)
        expect(subject.errors.first.value).to eq("789")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_oda_eligibility"))
      end

      it "has an error if the Activity Status option is invalid" do
        new_newton_activity_attributes["Activity Status"] = "99331"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Activity Status")
        expect(subject.errors.first.attribute_name).to eq(:programme_status)
        expect(subject.errors.first.value).to eq("99331")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_programme_status"))
      end

      it "has an error if the Sector option is invalid" do
        new_newton_activity_attributes["Sector"] = "53453453453453"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Sector")
        expect(subject.errors.first.attribute_name).to eq(:sector)
        expect(subject.errors.first.value).to eq("53453453453453")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_sector"))
      end

      it "has an error if the Collaboration type option is invalid" do
        new_newton_activity_attributes["Collaboration type (Bi/Multi Marker)"] = "99"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Collaboration type (Bi/Multi Marker)")
        expect(subject.errors.first.attribute_name).to eq(:collaboration_type)
        expect(subject.errors.first.value).to eq("99")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_collaboration_type"))
      end

      it "has an error if the Aid Type option is invalid" do
        new_newton_activity_attributes["Aid type"] = "1"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Aid type")
        expect(subject.errors.first.attribute_name).to eq(:aid_type)
        expect(subject.errors.first.value).to eq("1")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_aid_type"))
      end

      it "has an error if the Free Standing Technical Cooperation option is invalid" do
        new_newton_activity_attributes["Free Standing Technical Cooperation"] = "x"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Free Standing Technical Cooperation")
        expect(subject.errors.first.attribute_name).to eq(:fstc_applies)
        expect(subject.errors.first.value).to eq("x")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_fstc_applies"))
      end

      {
        "Planned start date" => :planned_start_date,
        "Planned end date" => :planned_end_date,
        "Actual start date" => :actual_start_date,
        "Actual end date" => :actual_end_date
      }.each do |attr_name, column_name|
        it "has an error if any the #{attr_name} is invalid" do
          new_newton_activity_attributes[attr_name] = "12/31/2020"

          expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

          expect(subject.created.count).to eq(0)
          expect(subject.updated.count).to eq(0)

          expect(subject.errors.count).to eq(1)
          expect(subject.errors.first.csv_row).to eq(2)
          expect(subject.errors.first.csv_column_name).to eq(attr_name)
          expect(subject.errors.first.attribute_name).to eq(column_name)
          expect(subject.errors.first.value).to eq("12/31/2020")
          expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_#{column_name}"))
        end
      end

      it "has an error if it fails dates_step validation" do
        new_newton_activity_attributes["Planned start date"] = nil
        new_newton_activity_attributes["Actual start date"] = nil

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(2)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Planned start date")
        expect(subject.errors.first.attribute_name).to eq(:planned_start_date)
        expect(subject.errors.first.value).to be_nil
        expect(subject.errors.first.message).to eq(I18n.t("activerecord.errors.models.activity.attributes.dates"))
      end

      it "has an error if the parent activity cannot be found" do
        new_newton_activity_attributes["Parent RODA ID"] = "111111"

        expect { subject.import([new_newton_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Parent RODA ID")
        expect(subject.errors.first.attribute_name).to eq(:parent_id)
        expect(subject.errors.first.value).to eq("111111")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.parent_not_found"))
      end

      context "when uploading new activities that you don't have permission for" do
        let(:activity_policy_double) { instance_double("ActivityPolicy", create_child?: false) }

        it "doesn't create the activity and reports the error" do
          subject.import([new_newton_activity_attributes])
          expect(subject.created.count).to eq(0)
          expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.unauthorised"))
        end
      end
    end

    context "when updating and creating in the same upload" do
      let(:activity_policy_double) { instance_double("ActivityPolicy", create_child?: true, update?: true) }
      let(:history_recorder) { instance_double(HistoryRecorder, call: true) }

      before do
        allow(ActivityPolicy).to receive(:new).and_return(activity_policy_double)
        allow(HistoryRecorder).to receive(:new).and_return(history_recorder)
      end

      it "creates and updates activities" do
        rows = [existing_newton_level_b_activity_attributes, new_newton_activity_attributes]

        expect { subject.import(rows) }.to change { Activity.count }.by(1)

        expect(subject.created.count).to eq(1)
        expect(subject.updated.count).to eq(1)

        expect(subject.errors.count).to eq(0)
      end

      describe "recording changes" do
        let(:expected_changes) do
          {
            "attr_1" => ["old attr_1 value", "new attr_1 value"],
            "attr_2" => ["old attr_2 value", "new attr_2 value"]
          }
        end

        before do
          allow(existing_newton_level_b_activity).to receive(:changes).and_return(expected_changes)
          allow(Activity).to receive(:by_roda_identifier).and_return(existing_newton_level_b_activity)
        end

        it "records the changes made using the HistoryRecorder" do
          rows = [existing_newton_level_b_activity_attributes, new_newton_activity_attributes]

          subject.import(rows)

          expect(HistoryRecorder).to have_received(:new).with(user: uploader)
          expect(history_recorder).to have_received(:call).with(
            reference: "Import from CSV",
            changes: expected_changes,
            activity: existing_newton_level_b_activity,
            trackable: existing_newton_level_b_activity,
            report: nil
          )
        end

        context "when the activity fails to update" do
          before do
            allow(existing_newton_level_b_activity).to receive(:save).and_return(false)
          end

          it "doesn't record any History" do
            rows = [existing_newton_level_b_activity_attributes, new_newton_activity_attributes]

            subject.import(rows)

            expect(history_recorder).not_to have_received(:call)
          end
        end
      end
    end
  end

  context "Importing GCRF fields" do
    let(:fund_activity) { create(:fund_activity, :gcrf) }

    let(:new_gcrf_activity_attributes) do
      generic_level_b_activity_attributes.merge({
        "RODA ID" => "",
        "Parent RODA ID" => fund_activity.roda_identifier,
        "Transparency identifier" => "23232332323",
        "Partner organisation identifier" => "9876543210",
        "GCRF Strategic Area" => "17A|RF",
        "GCRF Challenge Area" => "4"
      })
    end

    subject { described_class.new(uploader: uploader, partner_organisation: organisation, report: nil, is_oda: nil) }

    context "GCRF Challenge Area" do
      it "has an error if it's invalid" do
        new_gcrf_activity_attributes["GCRF Challenge Area"] = "invalid"

        expect { subject.import([new_gcrf_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("GCRF Challenge Area")
        expect(subject.errors.first.attribute_name).to eq(:gcrf_challenge_area)
        expect(subject.errors.first.value).to eq("invalid")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_gcrf_challenge_area"))
      end
    end
  end

  context "Importing ISPF fields" do
    let(:fund_activity) { create(:fund_activity, :ispf) }

    let(:existing_non_oda_programme) {
      create(
        :programme_activity,
        :ispf_funded,
        is_oda: false,
        extending_organisation: organisation
      )
    }

    let(:new_ispf_activity_attributes) do
      generic_level_b_activity_attributes.merge({
        "RODA ID" => "",
        "Parent RODA ID" => fund_activity.roda_identifier,
        "Transparency identifier" => "23232332323",
        "Partner organisation identifier" => "9876543210",
        "ISPF themes" => "4",
        "ISPF ODA partner countries" => "BR|EG",
        "ISPF non-ODA partner countries" => "CA"
      })
    end

    subject { described_class.new(uploader: uploader, partner_organisation: organisation, report: nil, is_oda: true) }

    context "ISPF themes" do
      it "has an error if it's invalid" do
        valid_code = "4"
        invalid_code = "99"
        codes = [valid_code, invalid_code].join("|")
        new_ispf_activity_attributes["ISPF themes"] = codes

        expect { subject.import([new_ispf_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("ISPF themes")
        expect(subject.errors.first.attribute_name).to eq(:ispf_themes)
        expect(subject.errors.first.value).to eq(codes)
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_ispf_themes", code: invalid_code))
      end
    end

    context "tags" do
      it "has an error if it's invalid" do
        valid_code = 1
        invalid_code = 99
        codes = [valid_code, invalid_code].join("|")
        new_ispf_activity_attributes["Tags"] = codes

        expect { subject.import([new_ispf_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("Tags")
        expect(subject.errors.first.attribute_name).to eq(:tags)
        expect(subject.errors.first.value).to eq(codes)
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_tags", code: invalid_code))
      end
    end

    context "ISPF ODA partner countries" do
      it "has an error if it's invalid" do
        valid_code = "BR"
        invalid_code = "XX"
        codes = [valid_code, invalid_code].join("|")
        new_ispf_activity_attributes["ISPF ODA partner countries"] = codes

        expect { subject.import([new_ispf_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("ISPF ODA partner countries")
        expect(subject.errors.first.attribute_name).to eq(:ispf_oda_partner_countries)
        expect(subject.errors.first.value).to eq(codes)
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_ispf_oda_partner_countries", code: invalid_code))
      end

      it "has an error if the upload contains None and some country codes" do
        country_code = "BR"
        none_country_code = "NONE"
        codes = [country_code, none_country_code].join("|")
        new_ispf_activity_attributes["ISPF ODA partner countries"] = codes

        expect { subject.import([new_ispf_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("ISPF ODA partner countries")
        expect(subject.errors.first.attribute_name).to eq(:ispf_oda_partner_countries)
        expect(subject.errors.first.value).to eq(codes)
        expect(subject.errors.first.message).to eq(t("activerecord.errors.models.activity.attributes.ispf_oda_partner_countries.none_exclusive"))
      end
    end

    context "ISPF non-ODA partner countries" do
      it "has an error if it's invalid" do
        valid_code = "CA"
        invalid_code = "XX"
        codes = [valid_code, invalid_code].join("|")
        new_ispf_activity_attributes["ISPF non-ODA partner countries"] = codes

        expect { subject.import([new_ispf_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column_name).to eq("ISPF non-ODA partner countries")
        expect(subject.errors.first.attribute_name).to eq(:ispf_non_oda_partner_countries)
        expect(subject.errors.first.value).to eq(codes)
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_ispf_non_oda_partner_countries", code: invalid_code))
      end

      context "when the activity is ODA" do
        it "has an error is the upload contains None" do
          new_ispf_activity_attributes["ISPF non-ODA partner countries"] = "NONE"

          expect { subject.import([new_ispf_activity_attributes]) }.to_not change { Activity.count }

          expect(subject.errors.count).to eq(1)
          expect(subject.errors.first.csv_row).to eq(2)
          expect(subject.errors.first.csv_column_name).to eq("ISPF non-ODA partner countries")
          expect(subject.errors.first.attribute_name).to eq(:ispf_non_oda_partner_countries)
          expect(subject.errors.first.value).to eq("NONE")
          expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.cannot_have_none_in_ispf_non_oda_partner_countries_on_oda_activity"))
        end
      end

      context "when the activity is non-ODA" do
        subject { described_class.new(uploader: uploader, partner_organisation: organisation, report: nil, is_oda: false) }

        it "has an error if the upload contains None and some country codes" do
          oda_specific_columns = ["Benefitting Countries", "GDI", "ODA Eligibility", "Aid type", "Aims/Objectives", "ISPF ODA partner countries", "Transparency identifier", "SDG 1", "SDG 2", "SDG 3"]
          oda_specific_columns.each { |column| new_ispf_activity_attributes.delete(column) }

          country_code = "CA"
          none_country_code = "NONE"
          codes = [country_code, none_country_code].join("|")
          new_ispf_activity_attributes["ISPF non-ODA partner countries"] = codes

          expect { subject.import([new_ispf_activity_attributes]) }.to_not change { Activity.count }

          expect(subject.created.count).to eq(0)
          expect(subject.updated.count).to eq(0)

          expect(subject.errors.count).to eq(1)
          expect(subject.errors.first.csv_row).to eq(2)
          expect(subject.errors.first.csv_column_name).to eq("ISPF non-ODA partner countries")
          expect(subject.errors.first.attribute_name).to eq(:ispf_non_oda_partner_countries)
          expect(subject.errors.first.value).to eq(codes)
          expect(subject.errors.first.message).to eq(t("activerecord.errors.models.activity.attributes.ispf_non_oda_partner_countries.none_exclusive"))
        end
      end
    end

    context "when the `activity_linking` feature flag is active" do
      before { allow(ROLLOUT).to receive(:active?).with(:activity_linking).and_return(true) }

      context "Linked activity RODA ID" do
        context "when creating a new activity" do
          it "links the new activity to the proposed existing Activity" do
            new_ispf_activity_attributes["Linked activity RODA ID"] = existing_non_oda_programme.roda_identifier

            subject.import([new_ispf_activity_attributes])

            expect(subject.errors.count).to eq(0)
            expect(subject.created.count).to eq(1)
            expect(subject.updated.count).to eq(0)

            expect(existing_non_oda_programme.reload.linked_activity.roda_identifier).to eq(subject.created.first.roda_identifier)
          end
        end

        context "when updating an existing activity" do
          let(:existing_oda_programme) {
            create(
              :programme_activity,
              :ispf_funded,
              is_oda: true,
              extending_organisation: organisation
            )
          }

          it "links the activity to the proposed existing Activity" do
            existing_oda_programme_attributes = {
              "RODA ID" => existing_oda_programme.roda_identifier,
              "Linked activity RODA ID" => existing_non_oda_programme.roda_identifier
            }

            subject.import([existing_oda_programme_attributes])

            expect(subject.errors.count).to eq(0)
            expect(subject.created.count).to eq(0)
            expect(subject.updated.count).to eq(1)

            expect(existing_non_oda_programme.reload.linked_activity).to eq(existing_oda_programme)
          end
        end
      end
    end
  end
end
