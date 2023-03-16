module BudgetRevisionsHelper
  def link_to_revisions(budget)
    update_audits_count = budget.audits.count { |audit| audit.action == "update" }
    return "None" if update_audits_count.zero?

    name = "#{update_audits_count} #{"revision".pluralize(update_audits_count)}"
    link_to(name, activity_budget_revisions_path(budget.parent_activity_id, budget), class: "govuk-link")
  end

  def row_header(audit)
    return "Original" if audit.action == "create"

    "Revision #{audit.version - 1}"
  end

  def difference(earlier_audit:, later_audit:)
    return if earlier_audit.nil?

    difference = later_audit.revision.value - earlier_audit.revision.value
    "#{"+" if difference.positive?}#{number_to_currency(difference, unit: "£")}"
  end
end
