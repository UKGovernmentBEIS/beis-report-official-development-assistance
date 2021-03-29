module Activities
  class ImportFromCsv
    Error = Struct.new(:row, :column, :value, :message) {
      def csv_row
        row + 2
      end

      def csv_column
        column_to_csv_column_mapping[column] || ImplementingOrganisationBuilder::FIELDS[column] || column.to_s
      end

      def column_to_csv_column_mapping
        Converter::FIELDS.merge(parent_id: "Parent RODA ID")
      end
    }

    attr_reader :errors, :created, :updated

    def self.column_headings
      ["Parent RODA ID"] + Converter::FIELDS.values
    end

    def initialize(organisation:)
      @organisation = organisation
      @errors = []
      @created = []
      @updated = []
    end

    def import(activities)
      ActiveRecord::Base.transaction do
        activities.each_with_index { |row, index| import_row(row, index) }

        if @errors.present?
          @created = []
          @updated = []
          raise ActiveRecord::Rollback
        end
      end
    end

    def import_row(row, index)
      action = row["RODA ID"].blank? ? create_activity(row, index) : update_activity(row, index)

      return if action.nil?

      action.errors.each do |attr_name, (value, message)|
        add_error(index, attr_name, value, message)
      end
    end

    def create_activity(row, index)
      if row["RODA ID Fragment"].present? && row["Parent RODA ID"].present?
        creator = ActivityCreator.new(@organisation, row)
        creator.create
        created << creator.activity unless creator.errors.any?

        creator
      else
        add_error(index, :roda_id, row["RODA ID"], I18n.t("importer.errors.activity.cannot_create")) && return
      end
    end

    def update_activity(row, index)
      if row["RODA ID Fragment"].present?
        add_error(index, :roda_identifier_fragment, row["RODA ID Fragment"], I18n.t("importer.errors.activity.cannot_update.fragment_present")) && return
      elsif row["Parent RODA ID"].present?
        add_error(index, :parent_id, row["Parent RODA ID"], I18n.t("importer.errors.activity.cannot_update.parent_present")) && return
      else
        updater = ActivityUpdater.new(row, @organisation)
        updater.update
        updated << updater.activity unless updater.errors.any?

        updater
      end
    end

    def add_error(row_number, column, value, message)
      @errors << Error.new(row_number, column, value, message)
    end

    class ActivityUpdater
      attr_reader :errors, :activity, :row

      def initialize(row, organisation)
        @errors = {}
        @activity = find_activity_by_roda_id(row["RODA ID"])
        @organisation = organisation
        @row = row
        @converter = Converter.new(row, :update)
        @errors.update(@converter.errors)
      end

      def update
        return unless @activity && @errors.empty?

        @activity.assign_attributes(@converter.to_h)

        implementing_organisation_builder = ImplementingOrganisationBuilder.new(@activity, row)
        implementing_organisation = implementing_organisation_builder.build

        @activity.implementing_organisations = [implementing_organisation] if implementing_organisation.valid?

        return if @activity.save

        @activity.errors.each do |attr_name, message|
          @errors[attr_name] ||= [@converter.raw(attr_name), message]
        end

        implementing_organisation_builder.add_errors(@errors)
      end

      def find_activity_by_roda_id(roda_id)
        activity = Activity.by_roda_identifier(roda_id)
        @errors[:roda_id] ||= [roda_id, I18n.t("importer.errors.activity.not_found")] if activity.nil?

        activity
      end
    end

    class ActivityCreator
      attr_reader :errors, :row, :activity

      def initialize(organisation, row)
        @organisation = organisation
        @errors = {}
        @row = row
        @converter = Converter.new(row)
        @parent_activity = fetch_parent(@row["Parent RODA ID"])
        @errors.update(@converter.errors)
      end

      def create
        return unless @errors.blank?

        @activity = Activity.new_child(
          parent_activity: @parent_activity,
          delivery_partner_organisation: @organisation
        ) { |a|
          a.form_state = "complete"
        }
        @activity.assign_attributes(@converter.to_h)
        @activity.cache_roda_identifier

        implementing_organisation_builder = ImplementingOrganisationBuilder.new(@activity, row)
        if row["Implementing organisation name"].present? || row["Implementing organisation sector"].present?
          implementing_organisation = implementing_organisation_builder.build
          @activity.implementing_organisations = [implementing_organisation]
        end

        return if @activity.save(context: Activity::VALIDATION_STEPS)

        @activity.errors.each do |attr_name, message|
          @errors[attr_name] ||= [@converter.raw(attr_name), message]
        end

        implementing_organisation_builder.add_errors(@errors) if @activity.implementing_organisations.any?
      end

      private def fetch_parent(roda_id)
        parent = Activity.by_roda_identifier(roda_id)

        @errors[:parent_id] = [roda_id, I18n.t("importer.errors.activity.parent_not_found")] if parent.nil?
        @errors[:parent_id] = [roda_id, I18n.t("importer.errors.activity.invalid_parent")] if parent.present? && !parent.form_steps_completed?

        parent
      end
    end

    class ImplementingOrganisationBuilder
      FIELDS = {
        "implementing_organisation_name" => "Implementing organisation name",
        "implementing_organisation_reference" => "Implementing organisation reference",
        "implementing_organisation_organisation_type" => "Implementing organisation sector",
      }.freeze

      attr_accessor :activity, :row

      def initialize(activity, row)
        @activity = activity
        @row = row
      end

      def build
        ImplementingOrganisation.find_or_initialize_by(
          activity_id: activity.id
        ) { |implementing_organisation|
          implementing_organisation.name = row["Implementing organisation name"]
          implementing_organisation.reference = row["Implementing organisation reference"]
          implementing_organisation.organisation_type = row["Implementing organisation sector"]
        }
      end

      def add_errors(errors)
        errors.delete(:implementing_organisations)

        implementing_organisation_errors = @activity.implementing_organisations.first.errors.messages
        errors["implementing_organisation_name"] = [row["Implementing organisation name"], implementing_organisation_errors[:name].first] if implementing_organisation_errors[:name].any?
        errors["implementing_organisation_organisation_type"] = [row["Implementing organisation sector"], implementing_organisation_errors[:organisation_type].first] if implementing_organisation_errors[:organisation_type].any?
        errors
      end
    end

    class Converter
      include ActivityHelper
      include CodelistHelper

      attr_reader :errors

      FIELDS = {
        transparency_identifier: "Transparency identifier",
        title: "Title",
        description: "Description",
        recipient_region: "Recipient Region",
        recipient_country: "Recipient Country",
        intended_beneficiaries: "Intended Beneficiaries",
        delivery_partner_identifier: "Delivery partner identifier",
        roda_identifier_fragment: "RODA ID Fragment",
        gdi: "GDI",
        gcrf_strategic_area: "GCRF Strategic Area",
        gcrf_challenge_area: "GCRF Challenge Area",
        sdg_1: "SDG 1",
        sdg_2: "SDG 2",
        sdg_3: "SDG 3",
        fund_pillar: "Newton Fund Pillar",
        covid19_related: "Covid-19 related research",
        oda_eligibility: "ODA Eligibility",
        oda_eligibility_lead: "ODA Eligibility Lead",
        programme_status: "Activity Status",
        call_open_date: "Call open date",
        call_close_date: "Call close date",
        total_applications: "Total applications",
        total_awards: "Total awards",
        planned_start_date: "Planned start date",
        planned_end_date: "Planned end date",
        actual_start_date: "Actual start date",
        actual_end_date: "Actual end date",
        sector: "Sector",
        channel_of_delivery_code: "Channel of delivery code",
        collaboration_type: "Collaboration type (Bi/Multi Marker)",
        policy_marker_gender: "DFID policy marker - Gender",
        policy_marker_climate_change_adaptation: "DFID policy marker - Climate Change - Adaptation",
        policy_marker_climate_change_mitigation: "DFID policy marker - Climate Change - Mitigation",
        policy_marker_biodiversity: "DFID policy marker - Biodiversity",
        policy_marker_desertification: "DFID policy marker - Desertification",
        policy_marker_disability: "DFID policy marker - Disability",
        policy_marker_disaster_risk_reduction: "DFID policy marker - Disaster Risk Reduction",
        policy_marker_nutrition: "DFID policy marker - Nutrition",
        aid_type: "Aid type",
        fstc_applies: "Free Standing Technical Cooperation",
        objectives: "Aims/Objectives (DP Definition)",
        beis_id: "BEIS ID",
        uk_dp_named_contact: "UK DP Named Contact",
        country_delivery_partners: "NF Partner Country DP",
      }

      ALLOWED_BLANK_FIELDS = [
        "DFID policy marker - Gender",
        "DFID policy marker - Climate Change - Adaptation",
        "DFID policy marker - Climate Change - Mitigation",
        "DFID policy marker - Biodiversity",
        "DFID policy marker - Desertification",
        "DFID policy marker - Disability",
        "DFID policy marker - Disaster Risk Reduction",
        "DFID policy marker - Nutrition",
        "Implementing organisation reference",
        "BEIS ID",
        "UK DP Named Contact (NF)",
        "NF Partner Country DP",
      ]

      def initialize(row, method = :create)
        @row = row
        @errors = {}
        @method = method
        @attributes = convert_to_attributes
      end

      def raw(attr_name)
        @row[FIELDS[attr_name]]
      end

      def to_h
        @attributes
      end

      def convert_to_attributes
        attributes = fields.each_with_object({}) { |(attr_name, column_name), attrs|
          attrs[attr_name] = convert_to_attribute(attr_name, @row[column_name]) if field_should_be_converted?(column_name)
        }

        if @method == :create
          attributes[:requires_additional_benefitting_countries] = (@row["Recipient Country"] && @row["Intended Beneficiaries"]).present?
          attributes[:call_present] = (@row["Call open date"] && @row["Call close date"]).present?
        end

        attributes[:geography] = infer_geography(attributes) if (attributes[:recipient_region] || attributes[:recipient_country]).present?
        attributes[:recipient_region] ||= inferred_region if attributes[:recipient_country].present?
        attributes[:sector_category] = get_sector_category(attributes[:sector]) if attributes[:sector].present?

        attributes
      end

      def fields
        return FIELDS if @method == :create

        columns_to_update = @row.to_h.reject { |_k, v| v.blank? }.keys
        converter_keys = FIELDS.select { |_k, v| columns_to_update.include?(v) }.keys
        FIELDS.slice(*converter_keys)
      end

      def field_should_be_converted?(column_name)
        ALLOWED_BLANK_FIELDS.include?(column_name) || @row[column_name].present?
      end

      def convert_to_attribute(attr_name, value)
        original_value = value.clone
        value = value.to_s.strip

        converter = "convert_#{attr_name}"
        value = __send__(converter, value) if respond_to?(converter)

        value
      rescue => error
        @errors[attr_name] = [original_value, error.message]
        nil
      end

      def convert_recipient_region(region)
        validate_from_codelist(
          region,
          "recipient_region",
          I18n.t("importer.errors.activity.invalid_region"),
        )
      end

      def convert_recipient_country(country)
        validate_country(
          country,
          I18n.t("importer.errors.activity.invalid_country")
        )
      end

      def convert_gdi(gdi)
        validate_from_codelist(
          gdi,
          "gdi",
          I18n.t("importer.errors.activity.invalid_gdi"),
        )
      end

      def convert_policy_marker(policy_marker)
        return "not_assessed" if policy_marker.blank?

        policy_markers_iati_codes_to_enum(policy_marker)
      end
      alias convert_policy_marker_gender convert_policy_marker
      alias convert_policy_marker_climate_change_adaptation convert_policy_marker
      alias convert_policy_marker_climate_change_mitigation convert_policy_marker
      alias convert_policy_marker_biodiversity convert_policy_marker
      alias convert_policy_marker_desertification convert_policy_marker
      alias convert_policy_marker_disability convert_policy_marker
      alias convert_policy_marker_disaster_risk_reduction convert_policy_marker
      alias convert_policy_marker_nutrition convert_policy_marker

      def convert_gcrf_challenge_area(gcrf_challenge_area)
        return nil if gcrf_challenge_area.blank?

        valid_codes = gcrf_challenge_area_options.map { |area| area.code.to_s }
        raise I18n.t("importer.errors.activity.invalid_gcrf_challenge_area") unless valid_codes.include?(gcrf_challenge_area)

        gcrf_challenge_area.to_i
      end

      def convert_gcrf_strategic_area(gcrf_strategic_area)
        gcrf_strategic_area.split("|").map do |code|
          valid_codes = gcrf_strategic_area_options.map { |area| area.code.to_s }
          raise I18n.t("importer.errors.activity.invalid_gcrf_strategic_area") unless valid_codes.include?(code)
          code
        end
      end

      def convert_sustainable_development_goal(goal)
        raise I18n.t("importer.errors.activity.invalid_sdg_goal") unless sdg_options.keys.map(&:to_s).include?(goal.to_s)

        goal
      end
      alias convert_sdg_1 convert_sustainable_development_goal
      alias convert_sdg_2 convert_sustainable_development_goal
      alias convert_sdg_3 convert_sustainable_development_goal

      def convert_intended_beneficiaries(intended_beneficiaries)
        intended_beneficiaries.split("|").map do |code|
          validate_country(
            code,
            I18n.t("importer.errors.activity.invalid_intended_beneficiaries")
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
        option = Activity.oda_eligibilities.key(oda_eligibility.to_i)

        raise I18n.t("importer.errors.activity.invalid_oda_eligibility") if option.nil?

        option
      end

      def convert_programme_status(programme_status)
        status = Activity.programme_statuses.key(programme_status.to_i)

        raise I18n.t("importer.errors.activity.invalid_programme_status") if status.nil?

        status
      end

      def convert_sector(sector)
        validate_from_codelist(
          sector,
          "sector",
          I18n.t("importer.errors.activity.invalid_sector"),
        )
      end

      def convert_channel_of_delivery_code(channel_of_delivery_code)
        validate_channel_of_delivery_code(
          channel_of_delivery_code,
          "channel_of_delivery_code",
          I18n.t("importer.errors.activity.invalid_channel_of_delivery_code"),
        )
      end

      def convert_collaboration_type(collaboration_type)
        validate_from_codelist(
          collaboration_type,
          "collaboration_type",
          I18n.t("importer.errors.activity.invalid_collaboration_type"),
        )
      end

      def convert_aid_type(aid_type)
        validate_from_codelist(
          aid_type,
          "aid_type",
          I18n.t("importer.errors.activity.invalid_aid_type"),
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

      def convert_country_delivery_partners(delivery_partners)
        delivery_partners.split("|").map(&:strip).reject(&:blank?)
      end

      def parse_date(date, message)
        return if date.blank?

        Date.strptime(date, "%d/%m/%Y").to_datetime
      rescue ArgumentError
        raise message
      end

      def get_sector_category(sector_code)
        codelist = Codelist.new(type: "sector")
        sector = codelist.find { |list_item| list_item["code"] == sector_code }

        sector["category"] if sector
      end

      def infer_geography(attributes)
        if attributes[:recipient_region].present?
          :recipient_region
        elsif attributes[:recipient_country].present?
          :recipient_country
        end
      end

      def inferred_region
        @inferred_region ||= begin
          return if @row["Recipient Region"].present?

          country_to_region_mapping.find { |pair| pair["country"] == @row["Recipient Country"] }&.fetch("region")
        end
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
        yaml = YAML.safe_load(File.read("#{Rails.root}/config/locales/codelists/#{IATI_VERSION}/iati.en.yml"))
        countries = yaml["en"]["activity"]["recipient_country"]

        raise error unless countries.key?(country)

        country
      end
    end
  end
end
