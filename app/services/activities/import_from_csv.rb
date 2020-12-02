module Activities
  class ImportFromCsv
    Error = Struct.new(:row, :column, :value, :message) {
      def csv_row
        row + 2
      end

      def csv_column
        Converter::FIELDS[column] || column.to_s
      end
    }

    attr_reader :errors, :created, :updated

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
      attr_reader :errors, :activity

      def initialize(row, organisation)
        @errors = {}
        @activity = find_activity_by_roda_id(row["RODA ID"])
        @organisation = organisation
        @converter = Converter.new(row)
        @errors.update(@converter.errors)
      end

      def update
        return unless @activity && @errors.empty?

        attributes = @converter.to_h

        return if @activity.update(attributes)

        @activity.errors.each do |attr_name, message|
          @errors[attr_name] ||= [@converter.raw(attr_name), message]
        end
      end

      def find_activity_by_roda_id(roda_id)
        activity = Activity.by_roda_identifier(roda_id)
        @errors[:roda_id] ||= [roda_id, I18n.t("importer.errors.activity.not_found")] if activity.nil?

        activity
      end
    end

    class ActivityCreator
      attr_reader :errors, :activity

      def initialize(organisation, row)
        @organisation = organisation
        @activity = Activity.new
        @errors = {}
        @converter = Converter.new(row)
        @errors.update(@converter.errors)
      end

      def create
        return unless @converter.errors.blank?

        @activity.organisation = @organisation
        @activity.reporting_organisation = @organisation

        @activity.assign_attributes(@converter.to_h)
        @activity.level = calculate_level
        @activity.cache_roda_identifier

        return if @activity.save(context: Activity::VALIDATION_STEPS)

        @activity.errors.each do |attr_name, message|
          @errors[attr_name] ||= [@converter.raw(attr_name), message]
        end
      end

      def calculate_level
        @activity&.parent&.child_level
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
        parent_id: "Parent RODA ID",
        gdi: "GDI",
        sdg_1: "SDG 1",
        sdg_2: "SDG 2",
        sdg_3: "SDG 3",
        covid19_related: "Covid-19 related research",
        oda_eligibility: "ODA Eligibility",
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
        collaboration_type: "Collaboration type (Bi/Multi Marker)",
        flow: "Flow",
        aid_type: "Aid type",
        fstc_applies: "Free Standing Technical Cooperation",
        objectives: "Aims/Objectives (DP Definition)",
      }

      def initialize(row)
        @row = row
        @errors = {}
        @attributes = convert_to_attributes
      end

      def raw(attr_name)
        @row[FIELDS[attr_name]]
      end

      def to_h
        @attributes
      end

      def convert_to_attributes
        attributes = FIELDS.each_with_object({}) { |(attr_name, column_name), attrs|
          attrs[attr_name] = convert_to_attribute(attr_name, @row[column_name]) if @row[column_name].present?
        }

        attributes[:geography] = infer_geography(attributes)
        attributes[:requires_additional_benefitting_countries] = (@row["Recipient Country"] && @row["Intended Beneficiaries"]).present?
        attributes[:recipient_region] ||= inferred_region
        attributes[:call_present] = (@row["Call open date"] && @row["Call close date"]).present?
        attributes[:sector_category] = get_sector_category(attributes[:sector])

        attributes
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
          :recipient_region,
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
          :gdi,
          I18n.t("importer.errors.activity.invalid_gdi"),
        )
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

      def convert_parent_id(roda_id)
        parent = Activity.by_roda_identifier(roda_id)

        raise I18n.t("importer.errors.activity.parent_not_found") if parent.nil?

        parent.id
      end

      def convert_covid19_related(covid19_related)
        codelist = covid19_related_radio_options.map(&:code).map(&:to_s)

        raise I18n.t("importer.errors.activity.invalid_covid19_related") unless codelist.include?(covid19_related.to_s)

        covid19_related
      end

      def convert_oda_eligibility(oda_eligibility)
        validate_from_codelist(
          oda_eligibility,
          :oda_eligibility,
          I18n.t("importer.errors.activity.invalid_oda_eligibility"),
        )
      end

      def convert_programme_status(programme_status)
        validate_from_codelist(
          programme_status,
          :programme_status,
          I18n.t("importer.errors.activity.invalid_programme_status"),
        )
      end

      def convert_sector(sector)
        validate_from_codelist(
          sector,
          :sector,
          I18n.t("importer.errors.activity.invalid_sector"),
        )
      end

      def convert_collaboration_type(collaboration_type)
        validate_from_codelist(
          collaboration_type,
          :collaboration_type,
          I18n.t("importer.errors.activity.invalid_collaboration_type"),
        )
      end

      def convert_flow(flow)
        validate_from_codelist(
          flow,
          :flow,
          I18n.t("importer.errors.activity.invalid_flow"),
        )
      end

      def convert_aid_type(aid_type)
        validate_from_codelist(
          aid_type,
          :aid_type,
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

      def parse_date(date, message)
        return if date.blank?

        Date.strptime(date, "%d/%m/%Y").to_datetime
      rescue ArgumentError
        raise message
      end

      def get_sector_category(sector_code)
        codelist = load_yaml(entity: :activity, type: :sector)
        sector = codelist.find { |list_item| list_item["code"] == sector_code }

        sector["category"] if sector
      end

      def infer_geography(attributes)
        attributes[:recipient_region].present? ? :recipient_region : :recipient_country
      end

      def inferred_region
        @inferred_region ||= begin
          return if @row["Recipient Region"].present?

          country_to_region_mapping.find { |pair| pair["country"] == @row["Recipient Country"] }["region"]
        end
      end

      def validate_from_codelist(code, entity, message)
        return nil if code.blank?

        codelist = load_yaml(entity: :activity, type: entity)
        valid_codes = codelist.map { |entry| entry.fetch("code") }

        raise message unless valid_codes.include?(code)

        code
      end

      def country_to_region_mapping
        yaml = YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/BEIS/country_to_region_mapping.yml"))
        yaml["data"]
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
