# Run me with `rails runner db/data/20210618122834_change_budget_types.rb`

Budget.where("budget_type IN (?)", [1, 2]).update_all(budget_type: 0)
