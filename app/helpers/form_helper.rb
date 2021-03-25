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
      User.roles.map { |id, name| OpenStruct.new(id: id, name: t("activerecord.attributes.user.roles.#{name}")) }
    end
  end

  def list_of_budget_types
    @list_of_budget_types ||= begin
      Budget::BUDGET_TYPES.map { |id, name| OpenStruct.new(id: id, name: t("form.label.budget.budget_type_options.#{name}")) }
    end
  end

  def list_of_budget_statuses
    @list_of_budget_statuses ||= begin
      Budget::STATUSES.map { |id, name| OpenStruct.new(id: id, name: t("form.label.budget.status_options.#{name}")) }
    end
  end

  def list_of_financial_quarters
    @list_of_financial_quarters ||= begin
      FinancialQuarter::QUARTERS.map { |id| OpenStruct.new(id: id, name: "Q#{id}") }
    end
  end

  def list_of_financial_years(years = FinancialYear.next_ten)
    @list_of_financial_years ||= begin
      years.map { |year| OpenStruct.new(id: year.to_i, name: year.to_s) }
    end
  end

  def user_active_options
    [
      OpenStruct.new(id: "true", name: t("form.user.active.active")),
      OpenStruct.new(id: "false", name: t("form.user.active.inactive")),
    ]
  end

  def scoped_parent_activities(activity:, user:)
    activities = case activity.level.to_sym
    when :fund
      Activity.none
    when :programme
      FindFundActivities.new(organisation: activity.organisation, user: user)
        .call
    when :project
      FindProgrammeActivities.new(organisation: activity.organisation, user: user)
        .call(eager_load_parent: false)
    when :third_party_project
      FindProjectActivities.new(organisation: activity.organisation, user: user)
        .call(eager_load_parent: false)
    end

    activities.where(form_state: "complete")
  end

  def create_activity_level_options(user:)
    authorised_levels = Activity.levels.select { |level|
      policy = Pundit.policy(user, level.to_sym)
      policy.create? || policy.update?
    }

    authorised_levels = authorised_levels.reject { |level| level == "fund" || level == "third_party_project" || level == "project" }

    authorised_levels.keys.map do |level|
      OpenStruct.new(
        level: level,
        name: custom_capitalisation(I18n.t("page_content.activity.level.#{level}")),
        description: I18n.t("form.hint.activity.level_step.#{level}")
      )
    end
  end
end
