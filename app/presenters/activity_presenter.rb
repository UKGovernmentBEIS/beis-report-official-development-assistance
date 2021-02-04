# frozen_string_literal: true

class ActivityPresenter < SimpleDelegator
  include CodelistHelper
  include ActivityHelper

  def aid_type
    return if super.blank?
    I18n.t("activity.aid_type.#{super.downcase}")
  end

  def aid_type_with_code
    return if aid_type.blank?
    "#{aid_type} (#{to_model.aid_type})"
  end

  def covid19_related
    I18n.t("activity.covid19_related.#{super}")
  end

  def sector
    return if super.blank?
    I18n.t("activity.sector.#{super}")
  end

  def sector_with_code
    return if sector.blank?
    "#{sector} (#{to_model.sector})"
  end

  def call_present
    return if super.nil?
    I18n.t("activity.call_present.#{super}")
  end

  def call_open_date
    return if super.blank?
    I18n.l(super)
  end

  def call_close_date
    return if super.blank?
    I18n.l(super)
  end

  def programme_status
    return if super.blank?
    I18n.t("activity.programme_status.#{super}")
  end

  def planned_start_date
    return if super.blank?
    I18n.l(super)
  end

  def planned_end_date
    return if super.blank?
    I18n.l(super)
  end

  def actual_start_date
    return if super.blank?
    I18n.l(super)
  end

  def actual_end_date
    return if super.blank?
    I18n.l(super)
  end

  def geography
    return if super.blank?
    I18n.t("activity.geography.#{super}")
  end

  def recipient_region
    return if super.blank?
    I18n.t("activity.recipient_region.#{super}")
  end

  def recipient_country
    return if super.blank?
    I18n.t("activity.recipient_country.#{super}")
  end

  def requires_additional_benefitting_countries
    return if super.nil?
    I18n.t("activity.requires_additional_benefitting_countries.#{super}")
  end

  def intended_beneficiaries
    return if super.blank?
    super.map { |item| I18n.t("activity.recipient_country.#{item}") }.to_sentence
  end

  def gdi
    return if super.blank?
    I18n.t("activity.gdi.#{super}")
  end

  def collaboration_type
    return if super.blank?
    I18n.t("activity.collaboration_type.#{super}")
  end

  def flow
    I18n.t("activity.flow.#{super}")
  end

  def flow_with_code
    "#{flow} (#{to_model.flow})"
  end

  def policy_marker_gender
    return if super.blank?
    I18n.t("activity.policy_markers.#{super}")
  end

  def policy_marker_climate_change_adaptation
    return if super.blank?
    I18n.t("activity.policy_markers.#{super}")
  end

  def policy_marker_climate_change_mitigation
    return if super.blank?
    I18n.t("activity.policy_markers.#{super}")
  end

  def policy_marker_biodiversity
    return if super.blank?
    I18n.t("activity.policy_markers.#{super}")
  end

  def policy_marker_desertification
    return if super.blank?
    I18n.t("activity.policy_markers.#{super}")
  end

  def policy_marker_disability
    return if super.blank?
    I18n.t("activity.policy_markers.#{super}")
  end

  def policy_marker_disaster_risk_reduction
    return if super.blank?
    I18n.t("activity.policy_markers.#{super}")
  end

  def policy_marker_nutrition
    return if super.blank?
    I18n.t("activity.policy_markers.#{super}")
  end

  def sustainable_development_goals
    if sdgs_apply == false && step_is_complete_or_next?(activity: self, step: :sustainable_development_goals)
      "Not applicable"
    else
      goals = [sdg_1, sdg_2, sdg_3].compact
      return if goals.blank?

      html = "<ol class=\"govuk-list govuk-list--number\">"

      goals.each do |goal|
        html += "<li>" + I18n.t("form.label.activity.sdg_options.#{goal}") + "</li>"
      end

      html += "</ol>"
      html.html_safe
    end
  end

  def gcrf_challenge_area
    return if super.blank?
    I18n.t(super, scope: "form.label.activity.gcrf_challenge_area_options")
  end

  def oda_eligibility
    return if super.blank?
    I18n.t("activity.oda_eligibility.#{super}")
  end

  def call_to_action(attribute)
    if send(attribute).blank?
      "add"
    else
      "edit"
    end
  end

  def display_title
    return "Untitled (#{id})" if title.nil?
    title
  end

  def parent_title
    return if parent.blank?
    parent.title
  end

  def level
    return if super.blank?
    activity_level = I18n.t("page_content.activity.level.#{super}")
    custom_capitalisation(activity_level)
  end

  def tied_status_with_code
    "#{I18n.t("activity.tied_status.#{tied_status}")} (#{tied_status})"
  end

  def finance_with_code
    "#{I18n.t("activity.finance.#{finance}")} (#{finance})"
  end

  def fund_pillar
    return if super.blank?
    I18n.t("page_content.activity.fund_pillar.#{super}")
  end

  def link_to_roda
    Rails.application.routes.url_helpers.organisation_activity_details_url(organisation, self, host: ENV["DOMAIN"]).to_s
  end

  def actual_total_for_report_financial_quarter(report:)
    return if super.blank?
    "%.2f" % super
  end

  def forecasted_total_for_report_financial_quarter(report:)
    return if super.blank?
    "%.2f" % super
  end

  def variance_for_report_financial_quarter(report:)
    return if super.blank?
    "%.2f" % super
  end

  def channel_of_delivery_code
    item = channel_of_delivery_codes.find { |item| item["code"] == super }
    return if item.blank?

    "#{item["code"]}: #{item["name"]}"
  end
end
