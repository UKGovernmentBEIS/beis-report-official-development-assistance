module FormHelper
  BENEFITTING_SUB_REGION_2_CODE = 3

  def list_of_organisations
    @list_of_organisations ||=
      [OpenStruct.new(name: "", id: ""), Organisation.sorted_by_name].flatten
  end

  def list_of_matched_effort_providers
    @list_of_matched_effort_providers ||= [
      OpenStruct.new(name: "", id: ""),
      Organisation.matched_effort_providers.active,
    ].flatten
  end

  def list_of_external_income_providers
    @list_of_external_income_providers ||= [
      OpenStruct.new(name: "", id: ""),
      Organisation.external_income_providers.active,
    ].flatten
  end

  def list_of_delivery_partners
    @list_of_delivery_partners ||= Organisation.delivery_partners
  end

  def list_of_reporting_organisations
    @list_of_reporting_organisations ||= Organisation.reporters
  end

  def list_of_financial_quarters
    @list_of_financial_quarters ||= FinancialQuarter::QUARTERS.map { |id| OpenStruct.new(id: id, name: "Q#{id}") }
  end

  def list_of_financial_years(years = FinancialYear.next_ten)
    @list_of_financial_years ||= years.map { |year| OpenStruct.new(id: year.to_i, name: year.to_s) }
  end

  def user_active_options
    [
      OpenStruct.new(id: "true", name: t("form.user.active.active")),
      OpenStruct.new(id: "false", name: t("form.user.active.inactive")),
    ]
  end

  def organisation_active_options
    [
      OpenStruct.new(id: "true", name: t("form.label.organisation.active.true")),
      OpenStruct.new(id: "false", name: t("form.label.organisation.active.false")),
    ]
  end

  def benefitting_regions_for_form
    BenefittingRegion.all_for_level_code(BENEFITTING_SUB_REGION_2_CODE)
  end

  def benefitting_countries_in_region_for_form(region)
    BenefittingCountry.non_graduated_for_region(region)
  end
end
