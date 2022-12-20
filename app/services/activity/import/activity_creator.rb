class Activity
  class Import
    class ActivityCreator
      attr_reader :errors, :row, :activity

      def initialize(row:, uploader:, partner_organisation:, report:, is_oda: nil)
        @uploader = uploader
        @partner_organisation = partner_organisation
        @errors = {}
        @row = row
        @parent_activity = fetch_and_validate_parent_activity(@row["Parent RODA ID"])
        @report = report
        @is_oda = is_oda
        @converter = Converter.new(row: @row, is_oda: @is_oda)

        if @parent_activity && !ActivityPolicy.new(@uploader, @parent_activity).create_child?
          @errors[:parent_id] = [nil, I18n.t("importer.errors.activity.unauthorised")]
          return
        end

        @errors.update(@converter.errors)
      end

      def create
        return unless @errors.blank?

        @activity = Activity.new_child(
          parent_activity: @parent_activity,
          partner_organisation: @partner_organisation,
          is_oda: @is_oda
        ) { |a|
          a.form_state = "complete"
        }

        attributes = @converter.to_h

        if @is_oda == false
          @errors.merge!(Activity::Import.invalid_non_oda_attribute_errors(
            activity: @activity,
            converted_attributes: attributes
          ))
        end

        return unless @errors.blank?

        @activity.assign_attributes(attributes)

        if @activity.sdg_1 || @activity.sdg_2 || @activity.sdg_3
          @activity.sdgs_apply = true
        end

        implementing_organisation_builder = ImplementingOrganisationBuilder.new(@activity, row)
        if row["Implementing organisation names"].present?
          participations = implementing_organisation_builder.participations
          @activity.implementing_org_participations = participations
        end

        if row["Comments"].present?
          @activity.comments.build(body: row["Comments"], report: @report, owner: @uploader, commentable: @activity)
        end

        return true if @activity.save(context: Activity::VALIDATION_STEPS)

        @activity.errors.each do |error|
          @errors[error.attribute] ||= [@converter.raw(error.attribute), error.message]
        end

        implementing_organisation_builder.add_errors(@errors) if @activity.implementing_organisations.include?(nil)
      end

      private def fetch_and_validate_parent_activity(parent_roda_id)
        parent = Activity.by_roda_identifier(parent_roda_id)

        @errors[:parent_id] = [parent_roda_id, I18n.t("importer.errors.activity.parent_not_found")] if parent.nil?
        @errors[:parent_id] = [parent_roda_id, I18n.t("importer.errors.activity.incomplete_parent")] if parent.present? && !parent.form_steps_completed?

        parent
      end
    end
  end
end
