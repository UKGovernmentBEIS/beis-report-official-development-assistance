module FormHelper
  def list_of_organisations
    @list_of_organisations ||=
      [OpenStruct.new(name: "", id: ""), Organisation.sorted_by_name].flatten
  end

  def list_of_user_roles
    @list_of_user_roles ||= begin
      User.roles.map { |id, name| OpenStruct.new(id: id, name: I18n.t("activerecord.attributes.user.roles.#{name}")) }
    end
  end

  def list_of_budget_types
    @list_of_budget_types ||= begin
      Budget::BUDGET_TYPES.map { |id, name| OpenStruct.new(id: id, name: I18n.t("activerecord.attributes.budget.budget_type.#{name}")) }
    end
  end

  def list_of_budget_statuses
    @list_of_budget_statuses ||= begin
      Budget::STATUSES.map { |id, name| OpenStruct.new(id: id, name: I18n.t("activerecord.attributes.budget.status.#{name}")) }
    end
  end
end
