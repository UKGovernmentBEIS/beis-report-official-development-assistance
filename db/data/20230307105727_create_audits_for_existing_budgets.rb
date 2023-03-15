# Run me with `rails runner db/data/20230307105727_create_audits_for_existing_budgets.rb`

# We are using the Audited Gem to create revisions for Budgets.
#
# The "Original" Budget will be the audit that is created when the
# Budget is first created. However, while this works for new Budgets,
# we must create an audit for all existing Budgets as well.
#
# Audited does not provide an easy way to do this. This uses a private
# method of the library, then updates the created_at attribute to match the
# updated_at attribute of the Budget itself (updated_at represents the time
# that the Budget was put in its current state and is our best guess at an
# original state).

Budget.class_eval do
  def backfill_audit
    write_audit(action: "create", audited_changes: audited_attributes,
      comment: audit_comment)

    Audited::Audit.find_by(auditable_type: "Budget", auditable_id: id).update!(created_at: updated_at)
  end
end

def budgets_without_create_audits
  Budget
    .includes(:audits)
    .select { |budget| budget.audits.none? { |audit| audit.action == "create" } }
end

def log_message
  %(
    Number of Budgets: #{Budget.count},
    Number of create Audits: #{Audited::Audit.where(action: "create").count},
    Number of Budgets without create Audits: #{budgets_without_create_audits.count}
  )
end

ActiveRecord::Base.transaction do
  puts "BEFORE: #{log_message}"

  budgets_without_create_audits.each(&:backfill_audit)

  puts "AFTER: #{log_message}"
end
