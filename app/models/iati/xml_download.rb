module Iati
  class XmlDownload
    delegate :url_helpers, to: "Rails.application.routes"
    attr_reader :organisation, :level, :fund

    def initialize(organisation:, level:, fund:)
      @organisation, @level, @fund = organisation, level, fund
    end

    def title
      "#{fund.name} IATI export for #{I18n.t("page_content.activity.level.#{level}")} activities"
    end

    def path
      url_helpers.send(action_name, id: organisation.id, format: :xml, fund: fund.short_name)
    end

    class << self
      LEVELS = (Activity.levels.keys - ["fund"])

      def all_for_organisation(organisation)
        LEVELS.map { |level|
          Fund.all.map { |fund|
            new(organisation: organisation, level: level, fund: fund)
          }
        }.flatten
      end
    end

    private def action_name
      "iati_#{level}_activities_exports_organisation_path"
    end
  end
end
