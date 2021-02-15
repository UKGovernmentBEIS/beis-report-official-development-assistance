class SetDefaultAttributesOnTransaction < ActiveRecord::Migration[6.0]
  def up
    transaction_scope = Transaction.includes(:parent_activity)

    transactions = transaction_scope.where(description: nil)
      .or(transaction_scope.where(transaction_type: nil))
      .or(transaction_scope.where(providing_organisation_name: nil))
      .or(transaction_scope.where(providing_organisation_type: nil))
      .or(transaction_scope.where(providing_organisation_reference: nil))

    transactions.each do |transaction|
      transaction.transaction_type = Transaction::DEFAULT_TRANSACTION_TYPE if transaction.transaction_type.blank?

      transaction.description = "#{transaction.financial_quarter_and_year} spend on #{transaction.parent_activity.title}" if transaction.description.blank?

      transaction.providing_organisation_name = transaction.parent_activity.providing_organisation.name if transaction.providing_organisation_name.blank?
      transaction.providing_organisation_type = transaction.parent_activity.providing_organisation.organisation_type if transaction.providing_organisation_type.blank?
      transaction.providing_organisation_reference = transaction.parent_activity.providing_organisation.iati_reference if transaction.providing_organisation_reference.blank?
      transaction.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
