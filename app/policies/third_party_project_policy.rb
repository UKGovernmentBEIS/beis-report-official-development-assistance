class ThirdPartyProjectPolicy < ProjectPolicy
  def create?
    !beis_user? && editable_report?
  end

  private

  def editable_report?
    # FIXME: Remove once 'level' form_step removed
    return false if record.is_a?(Symbol)

    Report.editable.exists?(organisation: record.organisation, fund: record.associated_fund)
  end
end
