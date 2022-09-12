class ThirdPartyProjectPolicy < ProjectPolicy
  def create?
    partner_organisation_user? && editable_report?
  end

  private

  def editable_report?
    Report.editable.exists?(organisation: record.organisation, fund: record.associated_fund)
  end
end
