class Activity
  class Updater
    include DateHelper
    include CodelistHelper
    include ActivityHelper

    DEFAULT_PROGRAMME_STATUS_FOR_FUNDS = "spend_in_progress"

    attr_reader :activity, :params

    def initialize(activity:, params:)
      @activity = activity
      @params = params
    end

    def update(step)
      set_default_programme_status_for_fund if activity.fund?

      updater = "set_#{step}"
      if respond_to?(updater, :include_private)
        __send__(updater)
      else
        assign_attributes_for_step(step)
      end
    end

    private

    def set_default_programme_status_for_fund
      activity.assign_attributes(programme_status: DEFAULT_PROGRAMME_STATUS_FOR_FUNDS)
    end

    def set_level
      activity.assign_attributes(level: params_for("level"))
    end

    def set_parent
      parent_id = params_for("parent")

      case activity.level.to_sym
      when :programme then UpdateActivityAsProgramme.new(activity: activity, parent_id: parent_id).call
      when :project then UpdateActivityAsProject.new(activity: activity, parent_id: parent_id).call
      when :third_party_project then UpdateActivityAsThirdPartyProject.new(activity: activity, parent_id: parent_id).call
      end
    end

    def set_identifier
      assign_attributes_for_step("delivery_partner_identifier")
    end

    def set_roda_identifier
      assign_attributes_for_step("roda_identifier_fragment")
      activity.cache_roda_identifier!
    end

    def set_purpose
      activity.assign_attributes(title: params_for("title"), description: params_for("description"))
    end

    def set_sector_category
      activity.assign_attributes(sector_category: params_for("sector_category"), sector: nil)
    end

    def set_call_dates
      activity.assign_attributes(
        call_open_date: format_date(date_params_for("call_open_date")),
        call_close_date: format_date(date_params_for("call_close_date")),
      )
    end

    def set_total_applications_and_awards
      activity.assign_attributes(total_applications: params_for("total_applications"), total_awards: params_for("total_awards"))
    end

    def set_country_delivery_partners
      country_delivery_partners = activity_params
        .permit(country_delivery_partners: [])
        .fetch("country_delivery_partners", []).reject(&:blank?)

      activity.assign_attributes(country_delivery_partners: country_delivery_partners)
    end

    def set_dates
      assign_inputs_on_dates_step
    end

    def set_geography
      activity.assign_attributes(geography: params_for("geography"), recipient_region: nil, recipient_country: nil)
    end

    def set_region
      activity.assign_attributes(recipient_region: params_for("recipient_region"))
    end

    def set_country
      recipient_country = params_for("recipient_country")

      if recipient_country.blank?
        activity.assign_attributes(recipient_country: nil)
      else
        inferred_region = country_to_region_mapping.find { |pair| pair["country"] == recipient_country }["region"]
        activity.assign_attributes(recipient_region: inferred_region, recipient_country: recipient_country)
      end
    end

    def set_intended_beneficiaries
      intended_beneficiaries = activity_params
        .permit(intended_beneficiaries: [])
        .fetch("intended_beneficiaries", []).drop(1)
      activity.assign_attributes(intended_beneficiaries: intended_beneficiaries)
    end

    def set_aid_type
      activity.assign_attributes(aid_type: params_for("aid_type"))
      if can_infer_fstc?(activity.aid_type)
        activity.fstc_applies = fstc_from_aid_type(activity.aid_type)
      end
    end

    def set_policy_markers
      activity.assign_attributes(
        policy_marker_gender: policy_markers_from_params("policy_marker_gender"),
        policy_marker_climate_change_adaptation: policy_markers_from_params("policy_marker_climate_change_adaptation"),
        policy_marker_climate_change_mitigation: policy_markers_from_params("policy_marker_climate_change_mitigation"),
        policy_marker_biodiversity: policy_markers_from_params("policy_marker_biodiversity"),
        policy_marker_desertification: policy_markers_from_params("policy_marker_desertification"),
        policy_marker_disability: policy_markers_from_params("policy_marker_disability"),
        policy_marker_disaster_risk_reduction: policy_markers_from_params("policy_marker_disaster_risk_reduction"),
        policy_marker_nutrition: policy_markers_from_params("policy_marker_nutrition"),
      )
    end

    def set_covid19_related
      activity.assign_attributes(covid19_related: params_for("covid19_related", 0))
    end

    def set_sustainable_development_goals
      activity.assign_attributes(activity_params.permit(:sdg_1, :sdg_2, :sdg_3, :sdgs_apply))
      unless activity.sdgs_apply?
        activity.assign_attributes(sdg_1: nil, sdg_2: nil, sdg_3: nil)
      end
    end

    def assign_attributes_for_step(step)
      activity.assign_attributes({step => params_for(step)})
    end

    def policy_markers_from_params(param)
      policy_markers_iati_codes_to_enum(params_for(param))
    end

    def activity_params
      params.require(:activity)
    end

    def params_for(attribute, default = nil)
      activity_params.permit(attribute).fetch(attribute, default)
    end

    def date_params_for(attribute)
      date = activity_params.permit(attribute)
      {
        day: date["#{attribute}(3i)"],
        month: date["#{attribute}(2i)"],
        year: date["#{attribute}(1i)"],
      }
    end

    def assign_inputs_on_dates_step
      %i[
        planned_start_date
        planned_end_date
        actual_start_date
        actual_end_date
      ].each do |date_attr|
        activity.assign_attributes(date_attr => validated_date(date_params_for(date_attr)))
      rescue InvalidDateError
        activity.errors.add(date_attr, I18n.t("activerecord.errors.models.activity.attributes.#{date_attr}.invalid"))
      end
    end

    def country_to_region_mapping
      Codelist.new(type: "country_to_region_mapping", source: "beis")
    end
  end
end
