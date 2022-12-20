class Activity
  class Import
    class ImplementingOrganisationBuilder
      FIELDS = {
        "implementing_organisation_names" => "Implementing organisation names"
      }.freeze

      attr_accessor :activity, :org_names

      def initialize(activity, row)
        @activity = activity
        @org_names = split_org_names(row)
      end

      def organisations
        @organisations ||= org_names.map { |name| Organisation.find_matching(name) }
      end

      def participations
        organisations.map do |organisation|
          OrgParticipation.new(activity: activity, organisation: organisation)
        end
      end

      def add_errors(errors)
        return unless organisations.include?(nil)

        errors.delete(:implementing_organisations)

        unknown_names = []
        organisations.each_with_index do |item, idx|
          next if item
          unknown_names << org_names[idx]
        end

        errors["implementing_organisation_names"] =
          [unknown_names.join(" | "), "is/are not a known implementing organisation(s)"]
        errors
      end

      private

      def split_org_names(row)
        return [] unless row["Implementing organisation names"]

        row["Implementing organisation names"].split("|").map(&:strip)
      end
    end
  end
end
