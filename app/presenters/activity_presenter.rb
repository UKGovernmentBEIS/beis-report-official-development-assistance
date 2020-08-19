# frozen_string_literal: true

class ActivityPresenter < SimpleDelegator
  include CodelistHelper

  def aid_type
    return if super.blank?
    I18n.t("activity.aid_type.#{super.downcase}")
  end

  def sector
    return if super.blank?
    I18n.t("activity.sector.#{super}")
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

  def flow
    return if super.blank?
    I18n.t("activity.flow.#{super}")
  end

  def call_to_action(attribute)
    send(attribute).present? ? "edit" : "add"
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
    I18n.t("page_content.activity.level.#{super}").capitalize
  end

  def link_to_roda
    Rails.application.routes.url_helpers.organisation_activity_details_url(organisation, self, host: ENV["DOMAIN"]).to_s
  end

  def transactions_total
    return if super.blank?
    "%.2f" % super
  end

  def actual_total_for_report_financial_quarter(report:)
    return if super.blank?
    "%.2f" % super
  end

  def forecasted_total_for_report_financial_quarter(report:)
    return if super.blank?
    "%.2f" % super
  end
end
