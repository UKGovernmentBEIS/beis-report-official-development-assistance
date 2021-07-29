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
            next unless organisation_has_activities_for_level_and_fund?(organisation, level, fund)

            new(organisation: organisation, level: level, fund: fund)
          }
        }.flatten.compact
      end

      private def organisation_has_activities_for_level_and_fund?(organisation, level, fund)
        Activity.send(level).where(
          source_fund_code: fund.id,
          extending_organisation: organisation
        ).present?
      end
    end

    private def action_name
      "iati_#{level}_activities_exports_organisation_path"
    end
  end
end
