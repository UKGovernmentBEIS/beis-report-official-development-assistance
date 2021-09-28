module TransactionHelpers
  def create_actual(attributes)
    create(:actual, parent_activity: project, report: reporting_cycle.report, **attributes)
  end

  def create_refund(attributes)
    create(:refund, parent_activity: project, report: reporting_cycle.report, **attributes)
  end

  def create_adjustment(attributes)
    adjustment_type = attributes.delete(:adjustment_type)
    create(:adjustment, adjustment_type, parent_activity: project, report: reporting_cycle.report, **attributes)
  end
end
