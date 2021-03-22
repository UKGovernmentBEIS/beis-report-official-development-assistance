class TransactionOrganisationValidator < ActiveModel::Validator
  def validate(transaction)
    if has_at_least_one_organisation_field?(transaction)
      transaction.errors.add(:receiving_organisation_name, :blank) if transaction.receiving_organisation_name.blank?
      transaction.errors.add(:receiving_organisation_type, :blank) if transaction.receiving_organisation_type.blank?
    end
  end

  private

  def has_at_least_one_organisation_field?(transaction)
    transaction.receiving_organisation_name.present? ||
      transaction.receiving_organisation_type.present? ||
      transaction.receiving_organisation_reference.present?
  end
end
