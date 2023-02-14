class Activity
  class RodaIdentifierGenerator
    def initialize(parent_activity:, extending_organisation:, is_non_oda: false)
      @parent_activity = parent_activity
      @extending_organisation = extending_organisation
      @is_non_oda = is_non_oda
    end

    def generate
      if parent_activity.child_level == "programme"
        programme_identifier
      else
        project_identifier
      end
    end

    private

    def programme_identifier
      non_oda_prefix = @is_non_oda ? "NODA" : nil

      [
        non_oda_prefix,
        parent_activity.roda_identifier,
        extending_organisation.beis_organisation_reference,
        component_identifier
      ].compact.join("-")
    end

    def project_identifier
      [
        parent_activity.roda_identifier,
        component_identifier
      ].join("-")
    end

    def component_identifier
      Nanoid.generate(size: 7, alphabet: characters_to_use)
    end

    def characters_to_use
      # This contains a string of all alphanumeric characters,
      # minus `0`, `1`, `I` and `O`, which can be easily
      # confused.
      "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
    end

    attr_reader :parent_activity, :extending_organisation, :level
  end
end
