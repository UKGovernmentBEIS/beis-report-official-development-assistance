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

  def status
    return if super.blank?
    I18n.t("activity.status.#{super}")
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
end
