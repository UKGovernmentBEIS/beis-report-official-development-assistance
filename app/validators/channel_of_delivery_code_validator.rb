class ChannelOfDeliveryCodeValidator < ActiveModel::Validator
  include CodelistHelper

  def validate(activity)
    valid_codes = beis_allowed_channel_of_delivery_codes

    unless activity.channel_of_delivery_code.in?(valid_codes)
      activity.errors.add(:channel_of_delivery_code,
        I18n.t("activerecord.errors.models.activity.attributes.channel_of_delivery_code.invalid"))
    end
  end
end
