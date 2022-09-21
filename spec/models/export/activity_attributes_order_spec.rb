RSpec.describe Export::ActivityAttributesOrder do
  describe ".attributes_in_order" do
    it "describes the attributes and order for exporting a report" do
      expect(described_class.attributes_in_order).to eq [
        :roda_identifier,
        :level,
        :parent_programme_identifier,
        :parent_programme_title,
        :parent_project_identifier,
        :parent_project_title,
        :partner_organisation_identifier,
        :beis_identifier,
        :transparency_identifier,
        :title,
        :description,
        :objectives,
        :benefitting_countries,
        :benefitting_region,
        :recipient_region,
        :recipient_country,
        :intended_beneficiaries,
        :gdi,
        :programme_status,
        :call_open_date,
        :call_close_date,
        :total_applications,
        :total_awards,
        :planned_start_date,
        :planned_end_date,
        :actual_start_date,
        :actual_end_date,
        :oda_eligibility,
        :oda_eligibility_lead,
        :aid_type,
        :fstc_applies,
        :channel_of_delivery_code,
        :sector,
        :collaboration_type,
        :flow,
        :finance,
        :tied_status,
        :covid19_related,
        :policy_marker_gender,
        :policy_marker_climate_change_adaptation,
        :policy_marker_climate_change_mitigation,
        :policy_marker_biodiversity,
        :policy_marker_desertification,
        :policy_marker_disability,
        :policy_marker_disaster_risk_reduction,
        :policy_marker_nutrition,
        :sdg_1,
        :sdg_2,
        :sdg_3,
        :gcrf_strategic_area,
        :gcrf_challenge_area,
        :fund_pillar,
        :country_partner_organisations,
        :uk_po_named_contact
      ]
    end
  end
end
