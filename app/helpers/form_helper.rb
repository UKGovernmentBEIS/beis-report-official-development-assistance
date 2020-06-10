module FormHelper
  def list_of_organisations
    @list_of_organisations ||=
      [OpenStruct.new(name: "", id: ""), Organisation.sorted_by_name].flatten
  end

  def list_of_delivery_partners
    @list_of_delivery_partners ||= Organisation.delivery_partners
  end

  def list_of_user_roles
    @list_of_user_roles ||= begin
      User.roles.map { |id, name| OpenStruct.new(id: id, name: I18n.t("activerecord.attributes.user.roles.#{name}")) }
    end
  end

  def list_of_budget_types
    @list_of_budget_types ||= begin
      Budget::BUDGET_TYPES.map { |id, name| OpenStruct.new(id: id, name: I18n.t("form.label.budget.budget_type_options.#{name}")) }
    end
  end

  def list_of_planned_disbursement_budget_types
    @list_of_planned_disbursement_budget_types ||= begin
      PlannedDisbursement::PLANNED_DISBURSEMENT_BUDGET_TYPES.map do |id, name|
        OpenStruct.new(
          id: id,
          name: I18n.t("form.label.planned_disbursement.planned_disbursement_type_options.#{name}.name"),
          description: I18n.t("form.label.planned_disbursement.planned_disbursement_type_options.#{name}.description")
        )
      end
    end
  end

  def list_of_budget_statuses
    @list_of_budget_statuses ||= begin
      Budget::STATUSES.map { |id, name| OpenStruct.new(id: id, name: I18n.t("form.label.budget.status_options.#{name}")) }
    end
  end

  def user_active_options
    [
      OpenStruct.new(id: "true", name: t("form.user.active.active")),
      OpenStruct.new(id: "false", name: t("form.user.active.inactive")),
    ]
  end
end
