require "rails_helper"

RSpec.describe Activity::Import do
  let(:organisation) { create(:partner_organisation) }
  let(:uploader) { create(:partner_organisation_user, organisation: organisation) }
  let(:parent_activity) { create(:programme_activity, :newton_funded, extending_organisation: organisation) }
  let(:fund_activity) { create(:fund_activity) }
  let!(:report) { create(:report, fund: fund_activity) }

  let(:orig_impl_org) { create(:implementing_organisation, name: "Original Impl. Org") }

  before do
    create(:implementing_organisation, name: "Impl. Org 1")
    create(:implementing_organisation, name: "Impl. Org 2")
  end

  # NB: 'let!' to prevent `to change { Activity.count }` from giving confusing results
  let!(:existing_activity) do
    create(:project_activity) do |activity|
      activity.implementing_organisations = [orig_impl_org]
    end
  end

  let(:existing_activity_attributes) do
    {
      "RODA ID" => existing_activity.roda_identifier,
      "Transparency identifier" => "13232332323",
      "Parent RODA ID" => "",
      "Title" => "Here is a title",
      "Description" => "Some description goes here...",
      "Benefitting Countries" => "KH|KP|ID",
      "Partner organisation identifier" => "1234567890",
      "GDI" => "1",
      "GCRF Strategic Area" => "17A|RF",
      "GCRF Challenge Area" => "4",
      "SDG 1" => "1",
      "SDG 2" => "2",
      "SDG 3" => "3",
      "Covid-19 related research" => "0",
      "ODA Eligibility" => "0",
      "ODA Eligibility Lead" => "Bruce Wayne",
      "Newton Fund Pillar" => "1",
      "Activity Status" => "1",
      "Call open date" => "02/01/2020",
      "Call close date" => "02/01/2020",
      "Total applications" => "12",
      "Total awards" => "12",
      "Planned start date" => "02/01/2020",
      "Actual start date" => "03/01/2020",
      "Planned end date" => "04/01/2020",
      "Actual end date" => "05/01/2020",
      "Sector" => "11220",
      "Channel of delivery code" => "11000",
      "Collaboration type (Bi/Multi Marker)" => "1",
      "DFID policy marker - Gender" => "0",
      "DFID policy marker - Climate Change - Adaptation" => "2",
      "DFID policy marker - Climate Change - Mitigation" => "1",
      "DFID policy marker - Biodiversity" => "2",
      "DFID policy marker - Desertification" => "3",
      "DFID policy marker - Disability" => "",
      "DFID policy marker - Disaster Risk Reduction" => "0",
      "DFID policy marker - Nutrition" => "",
      "Aid type" => "B03",
      "Free Standing Technical Cooperation" => "1",
      "Aims/Objectives" => "Foo bar baz",
      "BEIS ID" => "BEIS_ID_EXAMPLE_01",
      "UK PO Named Contact" => "Jo Soap",
      "NF Partner Country PO" => "Association of Example Companies (AEC) | | Board of Sample Organisations (BSO)",
      "Implementing organisation names" => "Impl. Org 1",
      "Comments" => "Cat"
    }
  end
  let(:new_activity_attributes) do
    existing_activity_attributes.merge({
      "RODA ID" => "",
      "Parent RODA ID" => parent_activity.roda_identifier,
      "Transparency identifier" => "23232332323",
      "Implementing organisation names" => "Impl. Org 2",
      "Comments" => "Kitten"
    })
  end

  subject { described_class.new(uploader: uploader, partner_organisation: organisation, report: report, is_oda: nil) }

  describe "::invalid_non_oda_attribute_errors" do
    let(:converted_level_b_oda_attributes) {
      {
        roda_identifier: "",
        linked_activity_id: "",
        title: "A title",
        description: "A description",
        benefitting_countries: "AO",
        partner_organisation_identifier: "",
        gdi: "4",
        oda_eligibility: "1",
        programme_status: "7",
        planned_start_date: "10/10/2020",
        planned_end_date: "10/10/2021",
        actual_start_date: "",
        actual_end_date: "",
        sector: "12182",
        aid_type: "D01",
        objectives: "Freetext objectives",
        ispf_themes: "1",
        ispf_oda_partner_countries: "BR|EG",
        comments: "This is a comment"
      }
    }

    context "Level B" do
      let(:activity) { create(:programme_activity, :ispf_funded, is_oda: true) }
      let(:error_translation) { t("importer.errors.activity.oda_attribute_in_non_oda_activity") }

      it "returns a hash with errors where ODA fields have been included in a non-ODA upload" do
        expect(Activity::Import.invalid_non_oda_attribute_errors(
          activity: activity, converted_attributes: converted_level_b_oda_attributes
        )).to eq(
          {
            aid_type: ["D01", error_translation],
            benefitting_countries: ["AO", error_translation],
            gdi: ["4", error_translation],
            objectives: ["Freetext objectives", error_translation],
            oda_eligibility: ["1", error_translation],
            ispf_oda_partner_countries: ["BR|EG", error_translation]
          }
        )
      end
    end

    context "Level C/D" do
      let(:activity) { create(:project_activity, :ispf_funded, is_oda: true) }
      let(:error_translation) { t("importer.errors.activity.oda_attribute_in_non_oda_activity") }

      let(:converted_level_c_d_oda_attributes) {
        converted_level_b_oda_attributes.merge(
          {
            covid19_related: "1",
            oda_eligibility_lead: "ODA lead 1",
            call_open_date: "11/01/2019",
            call_close_date: "11/05/2019",
            total_applications: "14",
            total_awards: "5",
            channel_of_delivery_code: "11000",
            collaboration_type: "1",
            policy_marker_gender: "gender",
            policy_marker_climate_change_adaptation: "adaptation",
            policy_marker_climate_change_mitigation: "mitigation",
            policy_marker_biodiversity: "biodiversity",
            policy_marker_desertification: "desertification",
            policy_marker_disability: "disability",
            policy_marker_disaster_risk_reduction: "reduction",
            policy_marker_nutrition: "nutrition",
            fstc_applies: "0",
            uk_po_named_contact: "Someone Somebody"
          }
        )
      }

      it "returns a hash with errors where ODA fields have been included in a non-ODA upload" do
        expect(Activity::Import.invalid_non_oda_attribute_errors(
          activity: activity, converted_attributes: converted_level_c_d_oda_attributes
        )).to eq(
          {
            aid_type: ["D01", error_translation],
            benefitting_countries: ["AO", error_translation],
            channel_of_delivery_code: ["11000", error_translation],
            collaboration_type: ["1", error_translation],
            covid19_related: ["1", error_translation],
            fstc_applies: ["0", error_translation],
            gdi: ["4", error_translation],
            objectives: ["Freetext objectives", error_translation],
            oda_eligibility_lead: ["ODA lead 1", error_translation],
            policy_marker_biodiversity: ["biodiversity", error_translation],
            policy_marker_climate_change_adaptation: ["adaptation", error_translation],
            policy_marker_climate_change_mitigation: ["mitigation", error_translation],
            policy_marker_desertification: ["desertification", error_translation],
            policy_marker_disability: ["disability", error_translation],
            policy_marker_disaster_risk_reduction: ["reduction", error_translation],
            policy_marker_gender: ["gender", error_translation],
            policy_marker_nutrition: ["nutrition", error_translation],
            ispf_oda_partner_countries: ["BR|EG", error_translation]
          }
        )
      end
    end
  end

  describe "::is_oda_by_type" do
    context "when passed `:ispf_oda` as the type" do
      it "returns true" do
        expect(Activity::Import.is_oda_by_type(type: :ispf_oda)).to be(true)
      end
    end

    context "when passed `:ispf_non_oda` as the type" do
      it "returns true" do
        expect(Activity::Import.is_oda_by_type(type: :ispf_non_oda)).to be(false)
      end
    end

    context "when passed `:non_ispf` as the type" do
      it "returns nil" do
        expect(Activity::Import.is_oda_by_type(type: :non_ispf)).to eq(nil)
      end
    end
  end

  context "when updating an existing activity" do
    let(:activity_policy_double) { instance_double("ActivityPolicy", update?: true) }

    before do
      allow(ActivityPolicy).to receive(:new).and_return(activity_policy_double)
    end

    it "has an error if an Activity does not exist" do
      existing_activity_attributes["RODA ID"] = "FAKE RODA ID"

      expect { subject.import([existing_activity_attributes]) }.to_not change { existing_activity }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)

      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("roda_id")
      expect(subject.errors.first.column).to eq(:roda_id)
      expect(subject.errors.first.value).to eq("FAKE RODA ID")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.not_found"))
    end

    it "has an error when both the ID and Parent ID are present, as this may overwrite the existing Parent ID" do
      existing_activity_attributes["Parent RODA ID"] = parent_activity.roda_identifier

      expect { subject.import([existing_activity_attributes]) }.to_not change { existing_activity }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Parent RODA ID")
      expect(subject.errors.first.column).to eq(:parent_id)
      expect(subject.errors.first.value).to eq(parent_activity.roda_identifier)
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.cannot_update.parent_present"))
    end

    it "does not fail when the import row has no implementing organisation" do
      expect(existing_activity.implementing_organisations.count).to eq(1)

      existing_activity_attributes["Implementing organisation names"] = nil

      subject.import([existing_activity_attributes])

      expect(subject.errors.count).to eq(0)
      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(1)

      expect(existing_activity.implementing_organisations.count).to equal(1)
    end

    it "does not allow users to update the original commitment figure" do
      existing_activity_attributes["Original commitment figure"] = "10000"

      expect { subject.import([existing_activity_attributes]) }.to_not change { existing_activity }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Original commitment figure")
      expect(subject.errors.first.column).to eq(:commitment)
      expect(subject.errors.first.value).to eq("10000")
      expect(subject.errors.first.message).to eq(
        "The original commitment figure cannot be updated via the bulk upload. Please remove the original commitment figure from this row and try again."
      )
    end

    it "updates an existing activity" do
      subject.import([existing_activity_attributes])

      expect(subject.errors.count).to eq(0)
      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(1)

      expect(existing_activity.reload.transparency_identifier).to eq(existing_activity_attributes["Transparency identifier"])
      expect(existing_activity.title).to eq(existing_activity_attributes["Title"])
      expect(existing_activity.description).to eq(existing_activity_attributes["Description"])
      expect(existing_activity.gdi).to eq("1")
      expect(existing_activity.gcrf_strategic_area).to eq(["17A", "RF"])
      expect(existing_activity.gcrf_challenge_area).to eq(4)
      expect(existing_activity.partner_organisation_identifier).to eq(existing_activity_attributes["Partner organisation identifier"])
      expect(existing_activity.fund_pillar).to eq(existing_activity_attributes["Newton Fund Pillar"].to_i)
      expect(existing_activity.covid19_related).to eq(0)
      expect(existing_activity.oda_eligibility).to eq("never_eligible")
      expect(existing_activity.oda_eligibility_lead).to eq(existing_activity_attributes["ODA Eligibility Lead"])
      expect(existing_activity.programme_status).to eq("delivery")
      expect(existing_activity.iati_status).to eq("2")
      expect(existing_activity.call_open_date).to eq(DateTime.parse(existing_activity_attributes["Call open date"]))
      expect(existing_activity.call_close_date).to eq(DateTime.parse(existing_activity_attributes["Call close date"]))
      expect(existing_activity.planned_start_date).to eq(DateTime.parse(existing_activity_attributes["Planned start date"]))
      expect(existing_activity.planned_end_date).to eq(DateTime.parse(existing_activity_attributes["Planned end date"]))
      expect(existing_activity.actual_start_date).to eq(DateTime.parse(existing_activity_attributes["Actual start date"]))
      expect(existing_activity.actual_end_date).to eq(DateTime.parse(existing_activity_attributes["Actual end date"]))
      expect(existing_activity.sector).to eq(existing_activity_attributes["Sector"])
      expect(existing_activity.sector_category).to eq("112")
      expect(existing_activity.channel_of_delivery_code).to eq(existing_activity_attributes["Channel of delivery code"])
      expect(existing_activity.collaboration_type).to eq(existing_activity_attributes["Collaboration type (Bi/Multi Marker)"])
      expect(existing_activity.policy_marker_gender).to eq("not_targeted")
      expect(existing_activity.policy_marker_climate_change_adaptation).to eq("principal_objective")
      expect(existing_activity.policy_marker_climate_change_mitigation).to eq("significant_objective")
      expect(existing_activity.policy_marker_biodiversity).to eq("principal_objective")
      expect(existing_activity.policy_marker_desertification).to eq("principal_objective_and_in_support_of_an_action_programme")
      expect(existing_activity.policy_marker_disability).to eq("not_assessed")
      expect(existing_activity.policy_marker_disaster_risk_reduction).to eq("not_targeted")
      expect(existing_activity.policy_marker_nutrition).to eq("not_assessed")
      expect(existing_activity.aid_type).to eq(existing_activity_attributes["Aid type"])
      expect(existing_activity.fstc_applies).to be(true)
      expect(existing_activity.objectives).to eq(existing_activity_attributes["Aims/Objectives"])
      expect(existing_activity.beis_identifier).to eq(existing_activity_attributes["BEIS ID"])
      expect(existing_activity.uk_po_named_contact).to eq(existing_activity_attributes["UK PO Named Contact"])
      expect(existing_activity.sdgs_apply).to be(true)

      expect(existing_activity.implementing_organisations.count).to eq(1)
      expect(existing_activity.implementing_organisations.first.name)
        .to eq("Impl. Org 1")

      expect(existing_activity.country_partner_organisations).to eq(["Association of Example Companies (AEC)", "Board of Sample Organisations (BSO)"])
      expect(existing_activity.form_state).to eq "complete"
    end

    it "sets form_state to complete" do
      subject.import([existing_activity_attributes])

      expect(existing_activity.reload.form_state).to eq "complete"
    end

    it "ignores any blank columns" do
      existing_activity_attributes["Title"] = ""
      existing_activity_attributes["Channel of delivery code"] = ""

      expect { subject.import([existing_activity_attributes]) }.to_not change { existing_activity.title }
      expect(subject.errors.count).to eq(0)
    end

    it "has an error and does not update any other activities if an Activity does not exist" do
      invalid_activity_attributes = existing_activity_attributes.merge({"RODA ID" => "FAKE RODA ID"})
      activities = [
        existing_activity_attributes,
        invalid_activity_attributes
      ]
      expect { subject.import(activities) }.to_not change { existing_activity }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)
      expect(subject.errors.count).to eq(1)
    end

    it "has an error if a policy marker is invalid" do
      existing_activity_attributes["DFID policy marker - Biodiversity"] = "3"
      existing_activity_attributes["DFID policy marker - Desertification"] = "bogus"
      subject.import([existing_activity_attributes])

      expect(subject.errors.count).to eq(2)
      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors[0].csv_row).to eq(2)
      expect(subject.errors[0].csv_column).to eq("DFID policy marker - Biodiversity")
      expect(subject.errors[0].column).to eq(:policy_marker_biodiversity)
      expect(subject.errors[0].value).to eq("3")
      expect(subject.errors[0].message).to eq(I18n.t("importer.errors.activity.invalid_policy_marker"))

      expect(subject.errors[1].csv_row).to eq(2)
      expect(subject.errors[1].csv_column).to eq("DFID policy marker - Desertification")
      expect(subject.errors[1].column).to eq(:policy_marker_desertification)
      expect(subject.errors[1].value).to eq("bogus")
      expect(subject.errors[1].message).to eq(I18n.t("importer.errors.activity.invalid_policy_marker"))
    end

    context "when carrying out a partial update" do
      let!(:old_activity_attributes) { existing_activity.attributes }

      let(:attributes) do
        attributes = existing_activity_attributes.map { |k, _v| [k, ""] }.to_h
        attributes["RODA ID"] = existing_activity.roda_identifier
        attributes
      end
      let(:changed_attributes) do
        (existing_activity.reload.attributes.to_a - old_activity_attributes.to_a).to_h.except("updated_at")
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

      it "has the expected errors if the activity is invalid and no implementing organisation" do
        existing_activity.sector_category = nil
        existing_activity.save(validate: false)

        attributes["Title"] = "New Title"

        subject.import([attributes])

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)
        expect(subject.errors.count).to eq(1)

        expect(subject.errors.first.message).to eq("Select a category")
      end

      it "has the expected errors if the activity is invalid and one or more implementing organisation is invalid" do
        attributes["Title"] = "New Title"
        attributes["Implementing organisation names"] = "Impl. Org 1 | Unknown 1 | Unknown 2"

        existing_activity.implementing_organisations.delete_all

        existing_activity.sector_category = nil
        existing_activity.save(validate: false)

        subject.import([attributes])

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)
        expect(subject.errors.count).to eq(2)

        expect(subject.errors.map(&:value)).to match_array([
          "Unknown 1 | Unknown 2",
          nil
        ])

        expect(subject.errors.map(&:message)).to match_array([
          "Select a category",
          "is/are not a known implementing organisation(s)"
        ])
      end
    end

    context "when you don't have permission to update the existing activities" do
      let(:activity_policy_double) { instance_double("ActivityPolicy", update?: false) }

      it "doesn't update the activity and reports the error" do
        subject.import([existing_activity_attributes])
        expect(subject.updated.count).to eq(0)
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.unauthorised"))
      end
    end

    context "when linking activities" do
      let(:existing_oda_programme) {
        create(
          :programme_activity,
          :ispf_funded,
          is_oda: true,
          extending_organisation: organisation
        )
      }

      let(:existing_non_oda_programme) {
        create(
          :programme_activity,
          :ispf_funded,
          is_oda: false,
          extending_organisation: organisation
        )
      }

      context "at project level" do
        let(:existing_oda_project) {
          create(
            :project_activity,
            :ispf_funded,
            is_oda: true,
            extending_organisation: organisation,
            parent: existing_oda_programme
          )
        }

        let(:existing_non_oda_project) {
          create(
            :project_activity,
            :ispf_funded,
            is_oda: false,
            extending_organisation: organisation,
            parent: existing_non_oda_programme
          )
        }

        it "links the activities" do
          existing_non_oda_project_attributes = {
            "RODA ID" => existing_non_oda_project.roda_identifier,
            "Linked activity RODA ID" => existing_oda_project.roda_identifier
          }

          existing_oda_programme.linked_activity = existing_non_oda_programme
          existing_oda_programme.save
          subject.import([existing_non_oda_project_attributes])

          expect(subject.errors.count).to eq(0)
          expect(subject.created.count).to eq(0)
          expect(subject.updated.count).to eq(1)

          expect(existing_non_oda_programme.reload.linked_activity).to eq(existing_oda_programme)
        end
      end
    end
  end

  context "when creating a new activity" do
    let(:activity_policy_double) { instance_double("ActivityPolicy", create_child?: true) }

    before do
      allow(ActivityPolicy).to receive(:new).with(uploader, parent_activity).and_return(activity_policy_double)
    end

    it "returns an error when the ID and fragments are not present" do
      existing_activity_attributes["RODA ID"] = ""

      expect { subject.import([existing_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("roda_id")
      expect(subject.errors.first.column).to eq(:roda_id)
      expect(subject.errors.first.value).to eq("")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.cannot_create"))
    end

    it "does not fail when the row has no implementing organisation" do
      new_activity_attributes["Implementing organisation names"] = nil
      new_activity_attributes["Implementing organisation reference"] = nil
      new_activity_attributes["Implementing organisation sector"] = nil
      rows = [new_activity_attributes]

      expect { subject.import(rows) }.to change { Activity.count }.by(1)

      expect(subject.created.count).to eq(1)
      expect(subject.updated.count).to eq(0)
      expect(subject.errors.count).to eq(0)
    end

    it "creates the activity" do
      rows = [new_activity_attributes]
      expect { subject.import(rows) }.to change { Activity.count }.by(1)

      expect(subject.created.count).to eq(1)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(0)

      new_activity = Activity.order(:created_at).last

      expect(new_activity.parent).to eq(parent_activity)
      expect(new_activity.source_fund_code).to eq(1)
      expect(new_activity.level).to eq("project")
      expect(new_activity.transparency_identifier).to eq(new_activity_attributes["Transparency identifier"])
      expect(new_activity.title).to eq(new_activity_attributes["Title"])
      expect(new_activity.description).to eq(new_activity_attributes["Description"])
      expect(new_activity.benefitting_countries).to eq(["KH", "KP", "ID"])
      expect(new_activity.gdi).to eq("1")
      expect(new_activity.gcrf_challenge_area).to eq(4)
      expect(new_activity.partner_organisation_identifier).to eq(new_activity_attributes["Partner organisation identifier"])
      expect(new_activity.covid19_related).to eq(0)
      expect(new_activity.oda_eligibility).to eq("never_eligible")
      expect(new_activity.oda_eligibility_lead).to eq(new_activity_attributes["ODA Eligibility Lead"])
      expect(new_activity.programme_status).to eq("delivery")
      expect(new_activity.iati_status).to eq("2")
      expect(new_activity.fund_pillar).to eq(new_activity_attributes["Newton Fund Pillar"].to_i)
      expect(new_activity.call_open_date).to eq(DateTime.parse(new_activity_attributes["Call open date"]))
      expect(new_activity.call_close_date).to eq(DateTime.parse(new_activity_attributes["Call close date"]))
      expect(new_activity.call_present).to be(true)
      expect(new_activity.planned_start_date).to eq(DateTime.parse(new_activity_attributes["Planned start date"]))
      expect(new_activity.planned_end_date).to eq(DateTime.parse(new_activity_attributes["Planned end date"]))
      expect(new_activity.actual_start_date).to eq(DateTime.parse(new_activity_attributes["Actual start date"]))
      expect(new_activity.actual_end_date).to eq(DateTime.parse(new_activity_attributes["Actual end date"]))
      expect(new_activity.sector).to eq(new_activity_attributes["Sector"])
      expect(new_activity.sector_category).to eq("112")
      expect(new_activity.channel_of_delivery_code).to eq(new_activity_attributes["Channel of delivery code"])
      expect(new_activity.collaboration_type).to eq(new_activity_attributes["Collaboration type (Bi/Multi Marker)"])
      expect(new_activity.aid_type).to eq(new_activity_attributes["Aid type"])
      expect(new_activity.fstc_applies).to be(true)
      expect(new_activity.objectives).to eq(new_activity_attributes["Aims/Objectives"])
      expect(new_activity.beis_identifier).to eq(new_activity_attributes["BEIS ID"])
      expect(new_activity.uk_po_named_contact).to eq(new_activity_attributes["UK PO Named Contact"])
      expect(new_activity.country_partner_organisations).to eq(["Association of Example Companies (AEC)", "Board of Sample Organisations (BSO)"])
      expect(new_activity.sdgs_apply).to be(true)
      expect(new_activity.publish_to_iati).to be(true)
    end

    context "with a parent activity that is incomplete" do
      it "doesn't allow the new activity to be created" do
        parent_activity.update!(form_state: "identifier")

        expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column).to eq("Parent RODA ID")
        expect(subject.errors.first.column).to eq(:parent_id)
        expect(subject.errors.first.value).to eq(parent_activity.roda_identifier)
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.incomplete_parent"))
      end
    end

    it "sets BEIS as the accountable organisation" do
      beis = create(:beis_organisation)

      subject.import([new_activity_attributes])

      new_activity = Activity.order(:created_at).last
      expect(new_activity.accountable_organisation_name).to eq beis.name
      expect(new_activity.accountable_organisation_reference).to eq beis.iati_reference
      expect(new_activity.accountable_organisation_type).to eq beis.organisation_type
    end

    it "sets form_state to complete" do
      subject.import([new_activity_attributes])

      new_activity = Activity.order(:created_at).last
      expect(new_activity.form_state).to eq "complete"
    end

    it "creates the associated implementing organisations" do
      rows = [new_activity_attributes]
      expect { subject.import(rows) }.to change { OrgParticipation.implementing.count }.by(1)

      new_activity = Activity.order(:created_at).last

      expect(new_activity.implementing_organisations.first.name).to eq(new_activity_attributes["Implementing organisation names"])
    end

    it "allows the Call Open and Close Dates to be blank" do
      new_activity_attributes["Call open date"] = ""
      new_activity_attributes["Call close date"] = ""

      expect { subject.import([new_activity_attributes]) }.to change { Activity.count }

      new_activity = Activity.order(:created_at).last

      expect(new_activity.call_open_date).to be_nil
      expect(new_activity.call_close_date).to be_nil
      expect(new_activity.call_present).to be(false)
    end

    it "has an error if the benefitting countries are invalid" do
      new_activity_attributes["Benefitting Countries"] = "ffsdfdsfsfds"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Benefitting Countries")
      expect(subject.errors.first.column).to eq(:benefitting_countries)
      expect(subject.errors.first.value).to eq("ffsdfdsfsfds")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_benefitting_countries"))
    end

    it "has an error if the benefitting countries are graduated or not from the list" do
      new_activity_attributes["Benefitting Countries"] = ["UK", "SC"]

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.errors.first.csv_column).to eq("Benefitting Countries")
      expect(subject.errors.first.column).to eq(:benefitting_countries)
      expect(subject.errors.first.value).to include("UK")
      expect(subject.errors.first.value).to include("SC")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_benefitting_countries"))
    end

    it "has an error if the GDI is invalid" do
      new_activity_attributes["GDI"] = "2222222"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("GDI")
      expect(subject.errors.first.column).to eq(:gdi)
      expect(subject.errors.first.value).to eq("2222222")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_gdi"))
    end

    context "GCRF Challenge Area" do
      it "has an error if its invalid" do
        new_activity_attributes["GCRF Challenge Area"] = "invalid"

        expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column).to eq("GCRF Challenge Area")
        expect(subject.errors.first.column).to eq(:gcrf_challenge_area)
        expect(subject.errors.first.value).to eq("invalid")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_gcrf_challenge_area"))
      end
    end

    ["SDG 1", "SDG 2", "SDG 3"].each.with_index(1) do |key, i|
      it "has an error if the #{i.ordinalize} sustainable development goal is invalid" do
        new_activity_attributes[key] = "9999999"

        expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column).to eq("SDG #{i}")
        expect(subject.errors.first.column).to eq("sdg_#{i}".to_sym)
        expect(subject.errors.first.value).to eq("9999999")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_sdg_goal"))
      end
    end

    it "has an error if the Fund Pillar option is invalid" do
      new_activity_attributes["Newton Fund Pillar"] = "9999999"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Newton Fund Pillar")
      expect(subject.errors.first.column).to eq(:fund_pillar)
      expect(subject.errors.first.value).to eq("9999999")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_fund_pillar"))
    end

    it "has an error if the Covid-19 related option is invalid" do
      new_activity_attributes["Covid-19 related research"] = "9999999"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Covid-19 related research")
      expect(subject.errors.first.column).to eq(:covid19_related)
      expect(subject.errors.first.value).to eq("9999999")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_covid19_related"))
    end

    it "has an error if the ODA Eligibility option is invalid" do
      new_activity_attributes["ODA Eligibility"] = "789"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("ODA Eligibility")
      expect(subject.errors.first.column).to eq(:oda_eligibility)
      expect(subject.errors.first.value).to eq("789")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_oda_eligibility"))
    end

    it "has an error if the Activity Status option is invalid" do
      new_activity_attributes["Activity Status"] = "99331"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Activity Status")
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
      expect(subject.errors.first.csv_column).to eq("Sector")
      expect(subject.errors.first.column).to eq(:sector)
      expect(subject.errors.first.value).to eq("53453453453453")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_sector"))
    end

    it "has an error if the 'Channel of delivery code' is invalid for BEIS" do
      new_activity_attributes["Channel of delivery code"] = "21019"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Channel of delivery code")
      expect(subject.errors.first.column).to eq(:channel_of_delivery_code)
      expect(subject.errors.first.value).to eq("21019")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_channel_of_delivery_code"))
    end

    context "when the activity is a project" do
      it "has an error if the 'Channel of delivery code' is empty" do
        new_activity_attributes["Parent RODA ID"] = parent_activity.roda_identifier
        new_activity_attributes["Channel of delivery code"] = ""

        expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column).to eq("Channel of delivery code")
        expect(subject.errors.first.column).to eq(:channel_of_delivery_code)
        expect(subject.errors.first.value).to eq("")
        expect(subject.errors.first.message).to eq(I18n.t("activerecord.errors.models.activity.attributes.channel_of_delivery_code.invalid"))
      end
    end

    it "has an error if the Collaboration type option is invalid" do
      new_activity_attributes["Collaboration type (Bi/Multi Marker)"] = "99"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Collaboration type (Bi/Multi Marker)")
      expect(subject.errors.first.column).to eq(:collaboration_type)
      expect(subject.errors.first.value).to eq("99")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_collaboration_type"))
    end

    it "has an error if the Aid Type option is invalid" do
      new_activity_attributes["Aid type"] = "1"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Aid type")
      expect(subject.errors.first.column).to eq(:aid_type)
      expect(subject.errors.first.value).to eq("1")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_aid_type"))
    end

    it "has an error if the Free Standing Technical Cooperation option is invalid" do
      new_activity_attributes["Free Standing Technical Cooperation"] = "x"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Free Standing Technical Cooperation")
      expect(subject.errors.first.column).to eq(:fstc_applies)
      expect(subject.errors.first.value).to eq("x")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_fstc_applies"))
    end

    {
      "Call open date" => :call_open_date,
      "Call close date" => :call_close_date,
      "Planned start date" => :planned_start_date,
      "Planned end date" => :planned_end_date,
      "Actual start date" => :actual_start_date,
      "Actual end date" => :actual_end_date
    }.each do |attr_name, column_name|
      it "has an error if any the #{attr_name} is invalid" do
        new_activity_attributes[attr_name] = "12/31/2020"

        expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(1)
        expect(subject.errors.first.csv_row).to eq(2)
        expect(subject.errors.first.csv_column).to eq(attr_name)
        expect(subject.errors.first.column).to eq(column_name)
        expect(subject.errors.first.value).to eq("12/31/2020")
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.invalid_#{column_name}"))
      end
    end

    it "has an error if it fails dates_step validation" do
      new_activity_attributes["Planned start date"] = nil
      new_activity_attributes["Actual start date"] = nil

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(2)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Planned start date")
      expect(subject.errors.first.column).to eq(:planned_start_date)
      expect(subject.errors.first.value).to be_nil
      expect(subject.errors.first.message).to eq(I18n.t("activerecord.errors.models.activity.attributes.dates"))
    end

    it "has an error if the parent activity cannot be found" do
      new_activity_attributes["Parent RODA ID"] = "111111"

      expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

      expect(subject.created.count).to eq(0)
      expect(subject.updated.count).to eq(0)

      expect(subject.errors.count).to eq(1)
      expect(subject.errors.first.csv_row).to eq(2)
      expect(subject.errors.first.csv_column).to eq("Parent RODA ID")
      expect(subject.errors.first.column).to eq(:parent_id)
      expect(subject.errors.first.value).to eq("111111")
      expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.parent_not_found"))
    end

    context "Original commitment figure" do
      context "when present and valid" do
        it "creates and sets the Commitment" do
          new_activity_attributes["Original commitment figure"] = "100.50"
          rows = [new_activity_attributes]

          expect { subject.import(rows) }.to change { Commitment.count }.by(1)
          new_activity = Activity.order(:created_at).last

          expect(new_activity.commitment.value).to eq(100.50)
        end
      end

      context "when present but invalid" do
        it "has an error" do
          new_activity_attributes["Original commitment figure"] = "Invalid!"
          rows = [new_activity_attributes]

          expect { subject.import(rows) }.not_to change { Commitment.count }
          new_activity = Activity.order(:created_at).last

          expect(new_activity.commitment).to be_nil

          expect(subject.errors.count).to eq(1)
          expect(subject.errors.first.csv_row).to eq(2)
          expect(subject.errors.first.csv_column).to eq("Original commitment figure")
          expect(subject.errors.first.column).to eq(:commitment)
          expect(subject.errors.first.message).to eq("Original commitment figure is invalid")
        end
      end

      context "when not present and creating a level D activity" do
        let(:activity_policy_double) { instance_double("ActivityPolicy", create_child?: true) }

        before do
          allow(ActivityPolicy).to receive(:new).with(
            uploader, existing_activity
          ).and_return(activity_policy_double)
        end

        it "has an error" do
          level_c_parent_roda_id = existing_activity.roda_identifier
          new_activity_attributes["Parent RODA ID"] = level_c_parent_roda_id
          new_activity_attributes["Original commitment figure"] = ""
          rows = [new_activity_attributes]

          subject.import(rows)

          expect(subject.errors.count).to eq(1)
          expect(subject.errors.first.csv_row).to eq(2)
          expect(subject.errors.first.csv_column).to eq("Original commitment figure")
          expect(subject.errors.first.column).to eq(:commitment)
          expect(subject.errors.first.message).to eq(
            "An original commitment figure is required for level D activities"
          )
        end
      end

      context "when not present and creating a non-level D activity" do
        it "doesn't set a commitment, nor raise an error" do
          new_activity_attributes["Original commitment figure"] = ""
          rows = [new_activity_attributes]
          subject.import(rows)

          expect(subject.errors.count).to eq(0)

          new_activity = Activity.order(:created_at).last
          expect(new_activity.commitment).to be_nil
        end
      end
    end

    context "implementing organisation" do
      it "does not set when left blank" do
        new_activity_attributes["Implementing organisation names"] = ""

        expect { subject.import([new_activity_attributes]) }.to change { Activity.count }.by(1)

        expect(subject.created.last.implementing_organisations).to be_empty
        expect(subject.created.count).to eq(1)
        expect(subject.updated.count).to eq(0)
        expect(subject.errors.count).to eq(0)
      end

      context "when the activity is an ISPF third-party project" do
        let(:parent_activity) { create(:project_activity, :ispf_funded) }

        it "has an error if it is left blank" do
          # When it has other required ISPF attributes
          new_activity_attributes["ISPF themes"] = "1"
          new_activity_attributes["ISPF ODA partner countries"] = "IN"
          # But it doesn't have implementing organisations
          new_activity_attributes["Implementing organisation names"] = ""

          expect { subject.import([new_activity_attributes]) }.to_not change { Activity.count }

          expect(subject.created.count).to eq(0)
          expect(subject.updated.count).to eq(0)

          expect(subject.errors.count).to eq(1)
          expect(subject.errors.first.csv_row).to eq(2)
          expect(subject.errors.first.csv_column).to eq("Implementing organisation names")
          expect(subject.errors.first.column).to eq(:implementing_organisation_names)
          expect(subject.errors.first.value).to eq("")
          expect(subject.errors.first.message).to eq(I18n.t("activerecord.errors.models.activity.attributes.implementing_organisation_id.blank"))
        end
      end
    end

    context "when the parent activity is a fund" do
      let(:beis_organisation) { create(:beis_organisation) }
      let!(:parent_activity) { create(:fund_activity, :newton, organisation: beis_organisation) }
      let(:uploader) { create(:beis_user) }

      it "creates a programme level activity correctly" do
        expect { subject.import([new_activity_attributes]) }.to change { Activity.count }.by(1)

        expect(subject.created.count).to eq(1)
        expect(subject.updated.count).to eq(0)

        expect(subject.errors.count).to eq(0)

        new_activity = Activity.order(:created_at).last

        expect(new_activity.level).to eq("programme")
        expect(new_activity.organisation).to eq(beis_organisation)
        expect(new_activity.extending_organisation).to eq(organisation)
      end
    end

    context "when uploading new activities that you don't have permission for" do
      let(:activity_policy_double) { instance_double("ActivityPolicy", create_child?: false) }

      it "doesn't create the activity and reports the error" do
        subject.import([new_activity_attributes])
        expect(subject.created.count).to eq(0)
        expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.unauthorised"))
      end
    end

    describe "validating ISPF-specific attributes" do
      context "when trying to create an ODA child activity on a parent non-ODA activity" do
        subject { described_class.new(uploader: uploader, partner_organisation: organisation, report: nil, is_oda: true) }
        let(:parent_activity) { create(:programme_activity, :ispf_funded, is_oda: false) }

        let(:new_oda_project_attributes) {
          new_activity_attributes.merge({
            "Parent RODA ID" => parent_activity.roda_identifier,
            "ISPF themes" => "4",
            "ISPF ODA partner countries" => "BR|EG",
            "Comments" => ""
          })
        }

        it "doesn't create the activity and reports the error" do
          subject.import([new_oda_project_attributes])
          expect(subject.created.count).to eq(0)
          expect(subject.errors.first.message).to eq(I18n.t("activerecord.errors.models.activity.attributes.parent.invalid"))
        end
      end

      context "when trying to create a non-ODA child activity on a parent ODA activity" do
        subject { described_class.new(uploader: uploader, partner_organisation: organisation, report: nil, is_oda: false) }
        let(:parent_activity) { create(:programme_activity, :ispf_funded, is_oda: true) }

        let(:new_non_oda_project_attributes) {
          {
            "RODA ID" => "",
            "Parent RODA ID" => parent_activity.roda_identifier,
            "Title" => "Here is a title",
            "Description" => "Some description goes here...",
            "Partner organisation identifier" => "1234567890",
            "Activity Status" => "1",
            "Call open date" => "02/01/2020",
            "Call close date" => "02/01/2020",
            "Total applications" => "12",
            "Total awards" => "12",
            "Planned start date" => "02/01/2020",
            "Actual start date" => "03/01/2020",
            "Planned end date" => "04/01/2020",
            "Actual end date" => "05/01/2020",
            "ISPF non-ODA partner countries" => "CA",
            "ISPF themes" => "4",
            "Sector" => "11220",
            "UK PO Named Contact" => "Jo Soap",
            "Implementing organisation names" => "Impl. Org 1",
            "Original commitment figure" => "10000"
          }
        }

        it "doesn't create the activity and reports the error" do
          subject.import([new_non_oda_project_attributes])
          expect(subject.created.count).to eq(0)
          expect(subject.errors.first.message).to eq(I18n.t("activerecord.errors.models.activity.attributes.parent.invalid"))
        end
      end
    end

    context "when linking activities" do
      subject { described_class.new(uploader: uploader, partner_organisation: organisation, report: nil, is_oda: true) }

      let(:fund_activity) { create(:fund_activity, :ispf) }

      let(:existing_oda_programme) {
        create(
          :programme_activity,
          :ispf_funded,
          is_oda: true,
          extending_organisation: organisation
        )
      }

      let(:existing_non_oda_programme) {
        create(
          :programme_activity,
          :ispf_funded,
          is_oda: false,
          extending_organisation: organisation
        )
      }

      before { allow(ActivityPolicy).to receive(:new).and_return(activity_policy_double) }

      context "when the `activity_linking` feature flag is active" do
        before { allow(ROLLOUT).to receive(:active?).with(:activity_linking).and_return(true) }

        context "at project level" do
          let(:existing_non_oda_project) {
            create(
              :project_activity,
              :ispf_funded,
              is_oda: false,
              extending_organisation: organisation,
              parent: existing_non_oda_programme
            )
          }

          before do
            existing_oda_programme.linked_activity = existing_non_oda_programme
            existing_oda_programme.save
          end

          it "links the new activity to the proposed activity" do
            new_oda_project_attributes = new_activity_attributes.merge({
              "Parent RODA ID" => existing_oda_programme.roda_identifier,
              "Linked activity RODA ID" => existing_non_oda_project.roda_identifier,
              "ISPF themes" => "4",
              "ISPF ODA partner countries" => "BR|EG",
              "Comments" => ""
            })

            subject.import([new_oda_project_attributes])

            expect(subject.errors.count).to eq(0)
            expect(subject.created.count).to eq(1)
            expect(subject.updated.count).to eq(0)

            expect(existing_non_oda_project.reload.linked_activity.roda_identifier).to eq(subject.created.first.roda_identifier)
          end
        end

        context "when the proposed linked activity cannot be found" do
          it "throws an error" do
            new_oda_project_attributes = new_activity_attributes.merge({
              "Parent RODA ID" => existing_oda_programme.roda_identifier,
              "Linked activity RODA ID" => "non-existent-roda-id",
              "ISPF theme" => "4",
              "ISPF ODA partner countries" => "BR|EG",
              "Comments" => ""
            })

            subject.import([new_oda_project_attributes])

            expect(subject.errors.count).to eq(1)
            expect(subject.created.count).to eq(0)
            expect(subject.updated.count).to eq(0)

            expect(subject.errors.first.message).to eq(I18n.t("importer.errors.activity.linked_activity_not_found"))
          end
        end
      end
    end

    context "when it's a non-ODA programme" do
      subject { described_class.new(uploader: uploader, partner_organisation: organisation, report: nil, is_oda: false) }

      let(:fund_activity) { create(:fund_activity, :ispf) }
      let(:ispf) { create(:fund_activity, :ispf) }
      let(:new_non_oda_programme_attributes) {
        {
          "RODA ID" => new_activity_attributes["RODA ID"],
          "Parent RODA ID" => ispf.roda_identifier,
          "Linked activity RODA ID" => "",
          "Title" => new_activity_attributes["Title"],
          "Description" => new_activity_attributes["Description"],
          "Partner organisation identifier" => new_activity_attributes["Partner organisation identifier"],
          "Activity Status" => new_activity_attributes["Activity Status"],
          "Planned start date" => new_activity_attributes["Planned start date"],
          "Planned end date" => new_activity_attributes["Planned end date"],
          "Actual start date" => new_activity_attributes["Actual start date"],
          "Actual end date" => new_activity_attributes["Actual end date"],
          "Sector" => new_activity_attributes["Sector"],
          "ISPF themes" => "4",
          "ISPF non-ODA partner countries" => "CA|US",
          "Comments" => new_activity_attributes["Comments"],
          "Tags" => "",
          "Original commitment figure" => "100000"
        }
      }

      before { allow(ActivityPolicy).to receive(:new).with(uploader, ispf).and_return(activity_policy_double) }

      it "prefixes the RODA identifier with 'NODA'" do
        expect { subject.import([new_non_oda_programme_attributes]) }.to change { Activity.count }.by(1)

        new_activity = Activity.order(:created_at).last

        expect(new_activity.roda_identifier).to start_with("NODA-")
      end

      it "sets publish_to_iati to false" do
        expect { subject.import([new_non_oda_programme_attributes]) }.to change { Activity.count }.by(1)

        new_activity = Activity.order(:created_at).last

        expect(new_activity.publish_to_iati).to be(false)
      end
    end
  end

  context "when updating and importing" do
    let(:activity_policy_double) { instance_double("ActivityPolicy", create_child?: true, update?: true) }
    let(:history_recorder) { instance_double(HistoryRecorder, call: true) }

    before do
      allow(ActivityPolicy).to receive(:new).and_return(activity_policy_double)
      allow(HistoryRecorder).to receive(:new).and_return(history_recorder)
    end

    it "creates and updates activities" do
      rows = [existing_activity_attributes, new_activity_attributes]

      expect { subject.import(rows) }.to change { Activity.count }.by(1)

      expect(subject.created.count).to eq(1)
      expect(subject.updated.count).to eq(1)

      expect(subject.errors.count).to eq(0)
    end

    it "imports a new comment and an existing comment" do
      rows = [existing_activity_attributes, new_activity_attributes]
      subject.import(rows)

      existing_activity = Activity.where(transparency_identifier: existing_activity_attributes["Transparency identifier"]).first
      new_activity = Activity.where(transparency_identifier: new_activity_attributes["Transparency identifier"]).first

      expect(subject.errors.count).to eq(0)
      # If there is a comment text, we add it to the activity
      expect(existing_activity.comments.first.body).to eq("Cat")
      expect(new_activity.comments.first.body).to eq("Kitten")
    end

    it "handles a lack of comments gracefully" do
      rows = [existing_activity_attributes, new_activity_attributes]
      rows[0]["Comments"] = ""
      rows[1]["Comments"] = ""
      subject.import(rows)

      existing_activity = Activity.where(transparency_identifier: existing_activity_attributes["Transparency identifier"]).first
      new_activity = Activity.where(transparency_identifier: new_activity_attributes["Transparency identifier"]).first

      expect(subject.errors.count).to eq(0)
      expect(existing_activity.comments).to be_empty
      expect(new_activity.comments).to be_empty
    end

    describe "recording changes" do
      subject do
        described_class.new(
          uploader: uploader,
          partner_organisation: organisation,
          report: report,
          is_oda: nil
        )
      end

      let(:expected_changes) do
        {
          "attr_1" => ["old attr_1 value", "new attr_1 value"],
          "attr_2" => ["old attr_2 value", "new attr_2 value"]
        }
      end

      before do
        allow(existing_activity).to receive(:changes).and_return(expected_changes)
        allow(Activity).to receive(:by_roda_identifier).and_return(existing_activity)
      end

      it "records the changes made using the HistoryRecorder" do
        rows = [existing_activity_attributes, new_activity_attributes]

        subject.import(rows)

        expect(HistoryRecorder).to have_received(:new).with(user: uploader)
        expect(history_recorder).to have_received(:call).with(
          reference: "Import from CSV",
          changes: expected_changes,
          activity: existing_activity,
          trackable: existing_activity,
          report: report
        )
      end

      context "when the activity fails to update" do
        before do
          allow(existing_activity).to receive(:save).and_return(false)
        end

        it "doesn't record any History" do
          rows = [existing_activity_attributes, new_activity_attributes]

          subject.import(rows)

          expect(history_recorder).not_to have_received(:call)
        end
      end
    end

    it "creates and updates implementing organisations" do
      rows = [existing_activity_attributes, new_activity_attributes]

      expect(OrgParticipation.all.map { |p| p.organisation.name })
        .to include("Original Impl. Org")
      expect(OrgParticipation.all.map { |p| p.organisation.name })
        .not_to include("Impl. Org 1", "Impl. Org 2")

      subject.import(rows)

      expect(OrgParticipation.all.map { |p| p.organisation.name })
        .not_to include("Original Impl. Org")
      expect(OrgParticipation.all.map { |p| p.organisation.name })
        .to include("Impl. Org 1", "Impl. Org 2")

      expect(subject.errors.count).to eq(0)
    end

    it "imports multiple implementing organisations for the same activity" do
      rows = [existing_activity_attributes.merge({
        "Implementing organisation names" => "Impl. Org 1 | Impl. Org 2"
      })]

      expect(existing_activity.implementing_organisations.map(&:name))
        .to include("Original Impl. Org")
      expect(existing_activity.implementing_organisations.map(&:name))
        .not_to include("Impl. Org 1", "Impl. Org 2")

      subject.import(rows)

      expect(existing_activity.reload.implementing_organisations.map(&:name))
        .not_to include("Original Impl. Org")
      expect(existing_activity.reload.implementing_organisations.map(&:name))
        .to include("Impl. Org 1", "Impl. Org 2")

      expect(subject.errors.count).to eq(0)
    end

    context "with existing implementing organisation" do
      let(:existing_activity) do
        create(:project_activity_with_implementing_organisations, implementing_organisations_count: 3)
      end

      it "leaves only one associated implementing organisation and updates it" do
        rows = [existing_activity_attributes]

        expect { subject.import(rows) }.to change { OrgParticipation.implementing.count }.by(-2)

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(1)

        expect(subject.errors.count).to eq(0)
      end

      it "doesn't erase existing imp orgs if not provided" do
        rows = [existing_activity_attributes]
        rows.first["Implementing organisation names"] = ""

        expect { subject.import(rows) }.to change { OrgParticipation.implementing.count }.by(0)

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(1)

        expect(subject.errors.count).to eq(0)
      end

      it "erases existing imp orgs if requested" do
        rows = [existing_activity_attributes]
        rows.first["Implementing organisation names"] = "|"

        expect { subject.import(rows) }.to change { OrgParticipation.implementing.count }.by(-3)

        expect(subject.created.count).to eq(0)
        expect(subject.updated.count).to eq(1)

        expect(subject.errors.count).to eq(0)
      end
    end
  end
end
