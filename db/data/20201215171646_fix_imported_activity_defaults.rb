class FixImportedActivityDefaults < ActiveRecord::Migration[6.0]
  def up
    if has_column?("form_state")
      activities_with_nil_form_state.update_all(form_state: "completed")
    end

    if has_column?("programme_status") && has_column?("status")
      activities_with_programme_status_but_no_iati_status.find_each do |activity|
        status = ProgrammeToIatiStatus.new.programme_status_to_iati_status(activity.programme_status)
        activity.update_column(:status, status)
      end
    end

    if has_column?("funding_organisation_name") && has_column?("funding_organisation_reference") && has_column?("funding_organisation_type")
      activities_with_empty_funding_organisation.find_each do |activity|
        activity.update_columns(
          funding_organisation_name: beis.name,
          funding_organisation_reference: beis.iati_reference,
          funding_organisation_type: beis.organisation_type
        )
      end
    end

    if has_column?("accountable_organisation_name") && has_column?("accountable_organisation_reference") && has_column?("accountable_organisation_type")
      activities_with_empty_accountable_organisation.find_each do |activity|
        activity.update_columns(
          accountable_organisation_name: beis.name,
          accountable_organisation_reference: beis.iati_reference,
          accountable_organisation_type: beis.organisation_type
        )
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def activities_with_nil_form_state
    non_fund_activities.where(form_state: nil)
  end

  def activities_with_programme_status_but_no_iati_status
    non_fund_activities.where(status: nil).where.not(programme_status: nil)
  end

  def activities_with_empty_funding_organisation
    non_fund_activities.where(
      funding_organisation_name: nil,
      funding_organisation_reference: nil,
      funding_organisation_type: nil
    )
  end

  def activities_with_empty_accountable_organisation
    non_fund_activities.where(
      accountable_organisation_name: nil,
      accountable_organisation_reference: nil,
      accountable_organisation_type: nil
    )
  end

  def non_fund_activities
    Activity.where.not(level: [nil, "fund"])
  end

  def has_column?(name)
    Activity.column_names.include?(name)
  end

  def beis
    @_beis ||= Organisation.find_by(service_owner: true)
  end
end
