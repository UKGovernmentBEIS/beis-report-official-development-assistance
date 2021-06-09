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

      service
    end
  end
end
