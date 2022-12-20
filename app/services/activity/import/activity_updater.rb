class Activity
  class Import
    class ActivityUpdater
      attr_reader :errors, :activity, :row, :report

      def initialize(row:, uploader:, partner_organisation:, report:, is_oda:)
        @errors = {}
        @activity = find_activity_by_roda_id(row["RODA ID"])
        @uploader = uploader
        @partner_organisation = partner_organisation
        @row = row
        @report = report
        @is_oda = is_oda
        @converter = Converter.new(row: @row, method: :update, is_oda: @is_oda)

        if @activity && !ActivityPolicy.new(@uploader, @activity).update?
          @errors[:roda_identifier] = [nil, I18n.t("importer.errors.activity.unauthorised")]
          return
        end

        @errors.update(@converter.errors)
      end

      def update
        return unless @activity && @errors.empty?

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

        # Note: users may depend on "|" successfully wiping the Implementing Organisations
        # and an empty value not changing the Implementing Organisations. See
        # https://dxw.zendesk.com/agent/tickets/16160
        if row["Implementing organisation names"].present?
          implementing_organisation_builder = ImplementingOrganisationBuilder.new(@activity, row)
          implementing_organisations = implementing_organisation_builder.organisations
          if implementing_organisations.include?(nil)
            implementing_organisation_builder.add_errors(@errors)
          else
            @activity.implementing_organisations = implementing_organisations
          end
        end

        if row["Comments"].present?
          @activity.comments.build(body: row["Comments"], report: @report, owner: @uploader)
        end

        changes = @activity.changes
        return set_errors unless @activity.save

        record_history(changes)
      end

      def find_activity_by_roda_id(roda_id)
        activity = Activity.by_roda_identifier(roda_id)
        @errors[:roda_id] ||= [roda_id, I18n.t("importer.errors.activity.not_found")] if activity.nil?

        activity
      end

      private

      def record_history(changes)
        HistoryRecorder
          .new(user: @uploader)
          .call(
            changes: changes,
            reference: "Import from CSV",
            activity: @activity,
            trackable: @activity,
            report: report
          )
      end

      def set_errors
        @activity.errors.each do |error|
          @errors[error.attribute] ||= [@converter.raw(error.attribute), error.message]
        end
      end
    end
  end
end
