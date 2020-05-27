class AddIatiIdsToExistingUksaData < ActiveRecord::Migration[6.0]
  def up
    lookup_hash = {
      "UKSA_C2_07ab" => "GB-GOV-13-GCRF-UKSA_CO_UKSA-34",
      "UKSA_C2_07a" => "GB-GOV-13-GCRF-UKSA_CO_UKSA-34",
      "UKSA_C1_01" => "GB-GOV-13-GCRF-UKSA_NS_UKSA-029",
      "UKSA_C1_02" => "GB-GOV-13-GCRF-UKSA_SN_UKSA-030",
      "UKSA_C2_03" => "GB-GOV-13-GCRF-UKSA_KE_UKSA-04",
      "UKSA_C2_04" => "GB-GOV-13-GCRF-UKSA_TZ_NP_UKSA-07",
      "UKSA_C1_03" => "GB-GOV-13-GCRF-UKSA_NS_UKSA-031",
      "UKSA_C2_09" => "GB-GOV-13-GCRF-UKSA_ID-MY_UKSA-08",
      "UKSA_C1_05" => "GB-GOV-13-GCRF-UKSA_ZA_UKSA-034",
      "UKSA_C2_06" => "GB-GOV-13-GCRF-UKSA_KE-RW_UKSA-13",
      "UKSA_C1_06" => "GB-GOV-13-GCRF-UKSA_NS_UKSA-035",
      "UKSA_C1_07" => "GB-GOV-13-GCRF-UKSA_PE_UKSA-036",
      "UKSA_C2_01" => "GB-GOV-13-GCRF-UKSA_MN_UKSA-16",
      "UKSA_C1_08" => "GB-GOV-13-GCRF-UKSA_ZA_UKSA-037",
      "UKSA_C2_08" => "GB-GOV-13-GCRF-UKSA_PE_UKSA-22",
      "UKSA_C2_02a" => "GB-GOV-13-GCRF-UKSA_VN_UKSA-21",
      "UKSA_C1_10" => "GB-GOV-13-GCRF-UKSA_NG_UKSA-039",
      "UKSA_C1_11" => "GB-GOV-13-GCRF-UKSA_PH_UKSA-040",
      "UKSA_C1_09" => "GB-GOV-13-GCRF-UKSA_ID_UKSA-038",
      "UKSA_C1_17" => "GB-GOV-13-GCRF-UKSA_MU_UKSA-46",
      "UKSA_C1_12" => "GB-GOV-13-GCRF-UKSA_MX_UKSA-041",
      "UKSA_C1_13" => "GB-GOV-13-GCRF-UKSA_NS_UKSA-042",
      "UKSA_C1_04" => "GB-GOV-13-GCRF-UKSA_NS_UKSA-032",
      "UKSA_C1_14" => "GB-GOV-13-GCRF-UKSA_NS_UKSA-043",
      "UKSA_C2_10a" => "GB-GOV-13-GCRF-UKSA_FJ_SB_VU_UKSA-43",
      "UKSA_C1_18" => "GB-GOV-13-GCRF-UKSA_CI_UKSA-047",
    }
    lookup_hash.each_pair do |roda_id, iati_id|
      project = Activity.find_by(identifier: roda_id)
      next unless project.present?

      project.update(previous_identifier: iati_id)
    end
  end

  def down
    updated_activity_ids = [
      "GB-GOV-13-GCRF-UKSA_CO_UKSA-34",
      "GB-GOV-13-GCRF-UKSA_CO_UKSA-34",
      "GB-GOV-13-GCRF-UKSA_NS_UKSA-029",
      "GB-GOV-13-GCRF-UKSA_SN_UKSA-030",
      "GB-GOV-13-GCRF-UKSA_KE_UKSA-04",
      "GB-GOV-13-GCRF-UKSA_TZ_NP_UKSA-07",
      "GB-GOV-13-GCRF-UKSA_NS_UKSA-031",
      "GB-GOV-13-GCRF-UKSA_ID-MY_UKSA-08",
      "GB-GOV-13-GCRF-UKSA_ZA_UKSA-034",
      "GB-GOV-13-GCRF-UKSA_KE-RW_UKSA-13",
      "GB-GOV-13-GCRF-UKSA_NS_UKSA-035",
      "GB-GOV-13-GCRF-UKSA_PE_UKSA-036",
      "GB-GOV-13-GCRF-UKSA_MN_UKSA-16",
      "GB-GOV-13-GCRF-UKSA_ZA_UKSA-037",
      "GB-GOV-13-GCRF-UKSA_PE_UKSA-22",
      "GB-GOV-13-GCRF-UKSA_VN_UKSA-21",
      "GB-GOV-13-GCRF-UKSA_NG_UKSA-039",
      "GB-GOV-13-GCRF-UKSA_PH_UKSA-040",
      "GB-GOV-13-GCRF-UKSA_ID_UKSA-038",
      "GB-GOV-13-GCRF-UKSA_MU_UKSA-46",
      "GB-GOV-13-GCRF-UKSA_MX_UKSA-041",
      "GB-GOV-13-GCRF-UKSA_NS_UKSA-042",
      "GB-GOV-13-GCRF-UKSA_NS_UKSA-032",
      "GB-GOV-13-GCRF-UKSA_NS_UKSA-043",
      "GB-GOV-13-GCRF-UKSA_FJ_SB_VU_UKSA-43",
      "GB-GOV-13-GCRF-UKSA_CI_UKSA-047",
    ]
    updated_activities = Activity.where(previous_identifier: updated_activity_ids)
    updated_activities.update(previous_identifier: nil)
  end
end
