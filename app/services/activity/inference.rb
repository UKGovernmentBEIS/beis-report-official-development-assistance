class Activity
  class Inference
    def self.service
      if Rails.env.development?
        build_service
      else
        @service ||= build_service
      end
    end

    def self.build_service
      service = FieldInference.new

      Codelist.new(source: "beis", type: "aid_type").each do |item|
        rule = service.on(:aid_type, item["code"])

        if item.key?("collaboration_type")
          rule.fix(:collaboration_type, item["collaboration_type"])
        end

        if item.key?("ftsc_applies")
          rule.fix(:fstc_applies, item["ftsc_applies"])
        end
      end

      Codelist.new(source: "beis", type: "accepted_collaboration_types_and_channel_of_delivery_mapping").each do |item|
        allowed_values = item["channel_of_delivery_code"]
        rule = service.on(:collaboration_type, item["code"])

        case allowed_values
        when String then rule.fix(:channel_of_delivery_code, allowed_values)
        when Array then rule.restrict(:channel_of_delivery_code, allowed_values)
        end
      end

      service
    end
  end
end
