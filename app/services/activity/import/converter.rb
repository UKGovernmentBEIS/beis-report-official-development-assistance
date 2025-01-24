class Activity
  class Import
    class Converter
      include ActivityHelper
      include CodelistHelper

      attr_reader :errors

      ALLOWED_BLANK_FIELDS = [
        "BEIS ID",
        "NF Partner Country PO"
      ]

      def initialize(row:, method: :create, is_oda: nil)
        @row = row
        @errors = {}
        @method = method
        @is_oda = is_oda
        @attributes = convert_to_attributes
      end

      def raw(attr_name)
        @row[Field.find_by_attribute_name(attribute_name: attr_name)&.heading]
      end

      def to_h
        @attributes
      end

      private

      def convert_to_attributes
        attributes = fields.each_with_object({}) do |field, attrs|
          attrs[field.attribute_name] = convert_to_attribute(field.attribute_name, @row[field.heading]) if field_should_be_converted?(field)
        end

        if @method == :create
          attributes[:call_present] = (@row["Call open date"] && @row["Call close date"]).present?
        end

        if attributes[:commitment]
          attributes[:commitment].transaction_date = attributes[:planned_start_date] || attributes[:actual_start_date]
        end

        attributes[:sector_category] = get_sector_category(attributes[:sector]) if attributes[:sector].present?

        attributes
      end

      def fields
        return Field.all if @method == :create

        columns_to_update = @row.to_h.reject { |_k, v| v.blank? }.keys

        Field.where_headings(headings: columns_to_update)
      end

      def field_should_be_converted?(field)
        return false if field.exclude_from_converter

        ALLOWED_BLANK_FIELDS.include?(field.heading) || @row[field.heading].present?
      end

      def convert_to_attribute(attr_name, value)
        original_value = value.clone
        value = value.to_s.strip

        converter = "convert_#{attr_name}"
        value = __send__(converter, value) if respond_to?(converter, true)

        value
      rescue => error
        @errors[attr_name] = [original_value, error.message]
        nil
      end

      def convert_gdi(gdi)
        validate_from_codelist(
          gdi,
          "gdi",
          I18n.t("importer.errors.activity.invalid_gdi")
        )
      end

      def convert_policy_marker(policy_marker)
        raise I18n.t("importer.errors.activity.invalid_policy_marker") if policy_marker.to_i.to_s != policy_marker

        marker = policy_markers_iati_codes_to_enum(policy_marker)
        raise I18n.t("importer.errors.activity.invalid_policy_marker") if marker.nil?

        marker
      end
      alias_method :convert_policy_marker_gender, :convert_policy_marker
      alias_method :convert_policy_marker_climate_change_adaptation, :convert_policy_marker
      alias_method :convert_policy_marker_climate_change_mitigation, :convert_policy_marker
      alias_method :convert_policy_marker_biodiversity, :convert_policy_marker
      alias_method :convert_policy_marker_disability, :convert_policy_marker
      alias_method :convert_policy_marker_disaster_risk_reduction, :convert_policy_marker
      alias_method :convert_policy_marker_nutrition, :convert_policy_marker

      def convert_policy_marker_desertification(policy_marker)
        raise I18n.t("importer.errors.activity.invalid_policy_marker") if policy_marker.to_i.to_s != policy_marker

        marker = policy_markers_desertification_iati_codes_to_enum(policy_marker)
        raise I18n.t("importer.errors.activity.invalid_policy_marker") if marker.nil?

        marker
      end

      def convert_gcrf_challenge_area(gcrf_challenge_area)
        return nil if gcrf_challenge_area.blank?

        valid_codes = gcrf_challenge_area_options.map { |area| area.code.to_s }
        raise I18n.t("importer.errors.activity.invalid_gcrf_challenge_area") unless valid_codes.include?(gcrf_challenge_area)

        Integer(gcrf_challenge_area)
      end

      def convert_gcrf_strategic_area(gcrf_strategic_area)
        gcrf_strategic_area.split("|").uniq.map do |code|
          valid_codes = gcrf_strategic_area_options.map { |area| area.code.to_s }
          raise I18n.t("importer.errors.activity.invalid_gcrf_strategic_area") unless valid_codes.include?(code)
          code
        end
      end

      def convert_sustainable_development_goal(goal)
        raise I18n.t("importer.errors.activity.invalid_sdg_goal") unless sdg_options.keys.map(&:to_s).include?(goal.to_s)

        goal
      end
      alias_method :convert_sdg_1, :convert_sustainable_development_goal
      alias_method :convert_sdg_2, :convert_sustainable_development_goal
      alias_method :convert_sdg_3, :convert_sustainable_development_goal

      def convert_benefitting_countries(benefitting_countries)
        benefitting_countries.split("|").uniq.map do |code|
          validate_country(
            code,
            I18n.t("importer.errors.activity.invalid_benefitting_countries")
          )
        end
      end

      def convert_covid19_related(covid19_related)
        codelist = covid19_related_radio_options.map(&:code).map(&:to_s)

        raise I18n.t("importer.errors.activity.invalid_covid19_related") unless codelist.include?(covid19_related.to_s)

        covid19_related
      end

      def convert_fund_pillar(fund_pillar)
        codelist = fund_pillar_radio_options.map(&:code).map(&:to_s)

        raise I18n.t("importer.errors.activity.invalid_fund_pillar") unless codelist.include?(fund_pillar.to_s)

        fund_pillar
      end

      def convert_oda_eligibility(oda_eligibility)
        begin
          numeric_eligibility = Integer(oda_eligibility)
        rescue
          raise I18n.t("importer.errors.activity.invalid_oda_eligibility")
        end

        option = Activity.oda_eligibilities.key(numeric_eligibility)

        raise I18n.t("importer.errors.activity.invalid_oda_eligibility") if option.nil?

        option
      end

      def convert_programme_status(programme_status)
        begin
          numeric_status = Integer(programme_status)
        rescue
          I18n.t("importer.errors.activity.invalid_programme_status")
        end
        status = Activity.programme_statuses.key(numeric_status)

        raise I18n.t("importer.errors.activity.invalid_programme_status") if status.nil?

        status
      end

      def convert_sector(sector)
        validate_from_codelist(
          sector,
          "sector",
          I18n.t("importer.errors.activity.invalid_sector")
        )
      end

      def convert_channel_of_delivery_code(channel_of_delivery_code)
        validate_channel_of_delivery_code(
          channel_of_delivery_code,
          "channel_of_delivery_code",
          I18n.t("importer.errors.activity.invalid_channel_of_delivery_code")
        )
      end

      def convert_collaboration_type(collaboration_type)
        validate_from_codelist(
          collaboration_type,
          "collaboration_type",
          I18n.t("importer.errors.activity.invalid_collaboration_type")
        )
      end

      def convert_aid_type(aid_type)
        validate_from_codelist(
          aid_type,
          "aid_type",
          I18n.t("importer.errors.activity.invalid_aid_type")
        )
      end

      def convert_fstc_applies(fstc_applies)
        raise I18n.t("importer.errors.activity.invalid_fstc_applies") unless ["1", "0"].include?(fstc_applies)

        fstc_applies
      end

      def convert_call_open_date(call_open_date)
        parse_date(call_open_date, I18n.t("importer.errors.activity.invalid_call_open_date"))
      end

      def convert_call_close_date(call_close_date)
        parse_date(call_close_date, I18n.t("importer.errors.activity.invalid_call_close_date"))
      end

      def convert_planned_start_date(planned_start_date)
        parse_date(planned_start_date, I18n.t("importer.errors.activity.invalid_planned_start_date"))
      end

      def convert_planned_end_date(planned_end_date)
        parse_date(planned_end_date, I18n.t("importer.errors.activity.invalid_planned_end_date"))
      end

      def convert_actual_start_date(actual_start_date)
        parse_date(actual_start_date, I18n.t("importer.errors.activity.invalid_actual_start_date"))
      end

      def convert_actual_end_date(actual_end_date)
        parse_date(actual_end_date, I18n.t("importer.errors.activity.invalid_actual_end_date"))
      end

      def convert_country_partner_organisations(partner_orgs)
        partner_orgs.split("|").map(&:strip).uniq.reject(&:blank?)
      end

      def convert_ispf_themes(ispf_themes)
        return [] if ispf_themes.blank?

        valid_codes = ispf_themes_options.map { |theme| theme.code.to_s }
        ispf_themes.split("|").uniq.map do |ispf_theme|
          raise I18n.t("importer.errors.activity.invalid_ispf_themes", code: ispf_theme) unless valid_codes.include?(ispf_theme)

          Integer(ispf_theme)
        end
      end

      def convert_ispf_oda_partner_countries(ispf_oda_partner_countries)
        valid_codes = ispf_partner_countries_options(oda: true).map { |country| country.code.to_s }

        ispf_oda_partner_countries.split("|").uniq.map do |code|
          unless valid_codes.include?(code)
            raise I18n.t("importer.errors.activity.invalid_ispf_oda_partner_countries", code: code)
          end

          code
        end
      end

      def convert_ispf_non_oda_partner_countries(ispf_non_oda_partner_countries)
        valid_codes = ispf_partner_countries_options(oda: false).map { |country| country.code.to_s }

        ispf_non_oda_partner_countries.split("|").uniq.map do |code|
          unless valid_codes.include?(code)
            raise I18n.t("importer.errors.activity.invalid_ispf_non_oda_partner_countries", code: code)
          end

          if @is_oda && code == "NONE"
            raise I18n.t("importer.errors.activity.cannot_have_none_in_ispf_non_oda_partner_countries_on_oda_activity")
          end

          code
        end
      end

      def convert_linked_activity_id(linked_activity_id)
        return if linked_activity_id.blank?

        linked_activity = Activity.by_roda_identifier(linked_activity_id)

        raise I18n.t("importer.errors.activity.linked_activity_not_found") if linked_activity.nil?

        linked_activity.id
      end

      def convert_tags(tags)
        return [] if tags.blank?

        valid_codes = tags_options.map { |tag| tag.code.to_s }
        tags.split("|").uniq.map do |tag|
          raise I18n.t("importer.errors.activity.invalid_tags", code: tag) unless valid_codes.include?(tag)

          Integer(tag)
        end
      end

      def convert_commitment(commitment_value)
        return if commitment_value.blank?

        converted_value = ConvertFinancialValue.new.convert(commitment_value.to_s)
        Commitment.new(value: converted_value)
      rescue ConvertFinancialValue::Error
        raise I18n.t("importer.errors.commitment.not_a_number")
      end

      def parse_date(date, message)
        return if date.blank?

        Date.strptime(date, "%d/%m/%Y").to_datetime
      rescue ArgumentError
        raise message
      end

      def get_sector_category(sector_code)
        codelist = Codelist.new(type: "sector")
        sector = codelist.find_item_by_code(sector_code)

        sector["category"] if sector
      end

      def validate_from_codelist(code, entity, message)
        return nil if code.blank?

        codelist = Codelist.new(type: entity)
        valid_codes = codelist.map { |entry| entry.fetch("code") }

        raise message unless valid_codes.include?(code)

        code
      end

      def validate_channel_of_delivery_code(code, entity, message)
        return nil if code.blank?

        valid_codes = beis_allowed_channel_of_delivery_codes

        raise message unless valid_codes.include?(code)

        code
      end

      def country_to_region_mapping
        Codelist.new(type: "country_to_region_mapping", source: "beis")
      end

      def validate_country(country, error)
        raise error unless BenefittingCountry.find_non_graduated_country_by_code(country)
        country
      end
    end
  end
end
