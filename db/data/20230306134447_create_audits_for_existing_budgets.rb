# Run me with `rails runner db/data/20230306134447_create_audits_for_existing_budgets.rb`

# We are using the Auditable Gem to create revisions for Budgets.

# The "Original" Budget will be the audit the is created when the
# Budget is first created. However, while this works for new Budgets,
# we must create an audit for all existing Budgets.

Budget.all()
