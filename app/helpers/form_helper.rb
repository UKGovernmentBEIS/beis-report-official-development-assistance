module FormHelper
  BENEFITTING_SUB_REGION_2_CODE = 3

  def list_of_matched_effort_providers
    @list_of_matched_effort_providers ||= Organisation.matched_effort_providers.active
  end

  def list_of_external_income_providers
    @list_of_external_income_providers ||= Organisation.external_income_providers.active
  end

  def list_of_partner_organisations
    @list_of_partner_organisations ||= Organisation.partner_organisations
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

  def list_of_budget_financial_years
    @list_of_budget_financial_years =
      FinancialYear.from_twenty_ten_to_ten_years_ahead.map { |fy|
        OpenStruct.new(id: fy.to_i, name: fy.to_s)
      }
  end

  def user_active_options
    [
      OpenStruct.new(id: "true", name: t("form.user.active.active")),
      OpenStruct.new(id: "false", name: t("form.user.active.inactive"))
    ]
  end

  def organisation_active_options
    [
      OpenStruct.new(id: "true", name: t("form.label.organisation.active.true")),
      OpenStruct.new(id: "false", name: t("form.label.organisation.active.false"))
    ]
  end

  def benefitting_regions_for_form
    BenefittingRegion.all_for_level_code(BENEFITTING_SUB_REGION_2_CODE)
  end

  def benefitting_countries_in_region_for_form(region)
    BenefittingCountry.non_graduated_for_region(region)
  end

  def all_benefitting_country_codes
    benefitting_regions_for_form
      .reduce([]) { |countries, region| countries << BenefittingCountry.non_graduated_for_region(region) }
      .flatten
      .map(&:code)
  end
end
