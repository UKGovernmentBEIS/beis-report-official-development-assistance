RSpec.shared_examples "valid activity XML" do
  it "contains a top-level activities element with the IATI version" do
    visit organisation_activity_path(organisation, activity, format: :xml)
    expect(xml.at("iati-activities/@version").text).to eq(IATI_VERSION.tr("_", "."))
  end

  it "contains the activity XML" do
    visit organisation_activity_path(organisation, activity, format: :xml)

    expect(xml.at("iati-activity/@default-currency").text).to eq(activity.default_currency)
    expect(xml.at("iati-activity/iati-identifier").text).to eq(activity.transparency_identifier)
  end

  it "contains the reporting organisation XML" do
    visit organisation_activity_path(organisation, activity, format: :xml)
    expect(xml.at("iati-activity/reporting-org/@ref").text).to eq(activity.service_owner.iati_reference)
    expect(xml.at("iati-activity/reporting-org/@type").text).to eq(activity.service_owner.organisation_type)
    expect(xml.at("iati-activity/reporting-org/narrative").text).to eq(activity.service_owner.name)
  end

  it "has the relevant funding organisation XML" do
    visit organisation_activity_path(organisation, activity, format: :xml)
    if activity.funding_organisation.present?
      expect(xml.at("iati-activity/participating-org[@role = '1']/@ref").text).to eq(activity.funding_organisation.iati_reference)
      expect(xml.at("iati-activity/participating-org[@role = '1']/@type").text).to eq(activity.funding_organisation.organisation_type)
      expect(xml.at("iati-activity/participating-org[@role = '1']/narrative").text).to eq(activity.funding_organisation.name)
    else
      expect(xml.at("iati-activity/participating-org[@role = '1']")).to be_nil
    end
  end

  it "contains the accountable organisation XML" do
    visit organisation_activity_path(organisation, activity, format: :xml)
    expect(xml.at("iati-activity/participating-org[@role = '2']/@ref").text).to eq(activity.accountable_organisation_reference)
    expect(xml.at("iati-activity/participating-org[@role = '2']/@type").text).to eq(activity.accountable_organisation_type)
    expect(xml.at("iati-activity/participating-org[@role = '2']/narrative").text).to eq(activity.accountable_organisation_name)
  end

  it "contains the extending organisation XML" do
    visit organisation_activity_path(organisation, activity, format: :xml)
    expect(xml.at("iati-activity/participating-org[@role = '3']/@ref").text).to eq(activity.extending_organisation.iati_reference)
    expect(xml.at("iati-activity/participating-org[@role = '3']/@type").text).to eq(activity.extending_organisation.organisation_type)
    expect(xml.at("iati-activity/participating-org[@role = '3']/narrative").text).to eq(activity.extending_organisation.name)
  end

  it "contains the implementing organisations XML" do
    visit organisation_activity_path(organisation, activity, format: :xml)

    implementing_organisations_xml = xml.xpath("iati-activity/participating-org[@role = '4']")
    implementing_organisation_refs = activity.implementing_organisations.pluck(:reference)
    implementing_organisation_types = activity.implementing_organisations.pluck(:organisation_type)
    implementing_organisation_names = activity.implementing_organisations.pluck(:name)

    implementing_organisations_xml.each do |organisation_xml|
      expect(implementing_organisation_refs).to include(organisation_xml.at("@ref").text)
      expect(implementing_organisation_types).to include(organisation_xml.at("@type").text)
      expect(implementing_organisation_names).to include(organisation_xml.at("narrative").text)
    end
  end

  it "contains the default value for Finance" do
    visit organisation_activity_path(organisation, activity, format: :xml)

    expect(xml.at("iati-activity/default-finance-type/@code").text).to eq("110")
  end

  it "contains the default value of 0% capital spend" do
    visit organisation_activity_path(organisation, activity, format: :xml)

    expect(xml.at("iati-activity/capital-spend/@percentage").text).to eq("0")
  end

  it "contains the default value for Tied Status" do
    visit organisation_activity_path(organisation, activity, format: :xml)

    expect(xml.at("iati-activity/default-tied-status/@code").text).to eq("5")
  end

  it "contains the default value for Flow type" do
    visit organisation_activity_path(organisation, activity, format: :xml)

    expect(xml.at("iati-activity/default-flow-type/@code").text).to eq("10")
  end

  it "contains the transaction XML" do
    transaction = create(:transaction, parent_activity: activity)
    visit organisation_activity_path(organisation, activity, format: :xml)
    expect(xml.at("iati-activity/transaction/description/narrative").text).to eq(transaction.description)
  end

  it "contains the budget XML" do
    budget = create(:budget, parent_activity: activity)
    visit organisation_activity_path(organisation, activity, format: :xml)
    expect(xml.at("iati-activity/budget/@type").text).to eq("1")
    expect(xml.at("iati-activity/budget/@status").text).to eq("2")
    expect(xml.at("iati-activity/budget/value").text).to eq(budget.value.to_s)
    expect(xml.at("iati-activity/budget/value/@currency").text).to eq(budget.currency)
    expect(xml.at("iati-activity/budget/period-start/@iso-date").text).to eq(budget.period_start_date.strftime("%Y-%m-%d"))
    expect(xml.at("iati-activity/budget/period-end/@iso-date").text).to eq(budget.period_end_date.strftime("%Y-%m-%d"))
  end

  it "contains the planned disbursement XML" do
    planned_disbursement = create(:planned_disbursement, parent_activity: activity)
    planned_disbursement_presenter = PlannedDisbursementXmlPresenter.new(planned_disbursement)

    visit organisation_activity_path(organisation, activity, format: :xml)

    expect(xml.xpath("//iati-activity/planned-disbursement/@type").text).to eq planned_disbursement_presenter.planned_disbursement_type
    expect(xml.xpath("//iati-activity/planned-disbursement/period-start/@iso-date").text).to eq planned_disbursement_presenter.period_start_date

    expect(xml.xpath("//iati-activity/planned-disbursement/value").text).to eq planned_disbursement_presenter.value
    expect(xml.xpath("//iati-activity/planned-disbursement/value/@currency").text).to eq planned_disbursement_presenter.currency
    expect(xml.xpath("//iati-activity/planned-disbursement/value/@value-date").text).to eq planned_disbursement_presenter.period_start_date

    expect(xml.xpath("//iati-activity/planned-disbursement/provider-org/@type").text).to eq planned_disbursement_presenter.providing_organisation_type
    expect(xml.xpath("//iati-activity/planned-disbursement/provider-org/@provider-activity-id").text).to eq ""
    expect(xml.xpath("//iati-activity/planned-disbursement/provider-org/@ref").text).to eq planned_disbursement_presenter.providing_organisation_reference
    expect(xml.xpath("//iati-activity/planned-disbursement/provider-org/narrative").text).to eq planned_disbursement_presenter.providing_organisation_name
  end
end
