require "nokogiri"
require "legacy_activity"

class IngestIatiActivities
  include CodelistHelper

  attr_accessor :file_io, :delivery_partner

  def initialize(delivery_partner:, file_io:)
    self.delivery_partner = delivery_partner
    self.file_io = file_io
  end

  def call
    doc = Nokogiri::XML(file_io, nil, "UTF-8")

    legacy_activity_nodes = doc.xpath("//iati-activity")

    legacy_activity_nodes = legacy_activity_nodes.select { |node| node.xpath("@hierarchy=2") }

    legacy_activity_nodes.each do |legacy_activity_node|
      legacy_activity = LegacyActivity.new(activity_node_set: legacy_activity_node, delivery_partner: delivery_partner)
      legacy_identifier = legacy_activity.identifier
      existing_activity = Activity.find_by(previous_identifier: legacy_identifier)

      next if existing_activity&.ingested?

      ActiveRecord::Base.transaction do
        roda_activity = if existing_activity.present?
          existing_activity
        else
          new_activity = Activity.new(delivery_partner_identifier: legacy_identifier, organisation: delivery_partner)
          add_identifiers(legacy_activity: legacy_activity, new_activity: new_activity)
          add_participating_organisation(delivery_partner: delivery_partner, new_activity: new_activity, legacy_activity: legacy_activity)
          add_title(legacy_activity: legacy_activity, new_activity: new_activity)
          add_description(legacy_activity: legacy_activity, new_activity: new_activity)
          add_statuses(legacy_activity: legacy_activity, new_activity: new_activity)
          add_sector(legacy_activity: legacy_activity, new_activity: new_activity)
          add_flow(legacy_activity: legacy_activity, new_activity: new_activity)
          add_aid_type(legacy_activity: legacy_activity, new_activity: new_activity)
          add_dates(legacy_activity: legacy_activity, new_activity: new_activity)
          add_geography(legacy_activity: legacy_activity, new_activity: new_activity)

          new_activity.form_state = :complete
          new_activity
        end

        legacy_activity_parent = legacy_activity.find_parent
        roda_activity.parent = legacy_activity_parent
        roda_activity.level = legacy_activity_parent.child_level

        roda_activity.legacy_iati_xml = legacy_activity.to_xml.squish
        roda_activity.ingested = true

        add_transactions(legacy_activity: legacy_activity, roda_activity: roda_activity)
        add_budgets(legacy_activity: legacy_activity, roda_activity: roda_activity)
        add_planned_disbursements(legacy_activity: legacy_activity, roda_activity: roda_activity)

        roda_activity.save!
      end
    end
  end

  private def add_title(legacy_activity:, new_activity:)
    title = legacy_activity.elements[2].children.detect { |child| child.name.eql?("narrative") }.children.text if legacy_activity.elements[2].name.eql?("title")
    new_activity.title = normalize_string(title)
  end

  private def add_description(legacy_activity:, new_activity:)
    description = legacy_activity.elements[3].children.detect { |child| child.name.eql?("narrative") }.children.text if legacy_activity.elements[3].name.eql?("description")
    new_activity.description = normalize_string(description)
  end

  private def add_statuses(legacy_activity:, new_activity:)
    activity_status = legacy_activity.elements.at_xpath("//activity-status/@code")&.value
    new_activity.status = activity_status

    new_activity.programme_status = case activity_status
    when "3" then "08"
    when "4" then "09"
    else
      "Replace me"
    end
  end

  private def add_sector(legacy_activity:, new_activity:)
    sector = legacy_activity.elements.detect { |element| element.name.eql?("sector") }.attributes["code"].value
    new_activity.sector_category = sector_category_code(sector_code: sector)
    new_activity.sector = sector
  end

  private def add_flow(legacy_activity:, new_activity:)
    new_activity.flow = legacy_activity.elements.detect { |element| element.name.eql?("default-flow-type") }.attributes["code"].value
  end

  private def add_aid_type(legacy_activity:, new_activity:)
    new_activity.aid_type = legacy_activity.elements.at_xpath("//default-aid-type/@code").to_s
  end

  private def add_participating_organisation(delivery_partner:, new_activity:, legacy_activity:)
    reporting_org_reference = legacy_activity.elements[1].attributes["ref"].value if legacy_activity.elements[1].name.eql?("reporting-org")
    new_activity.reporting_organisation = Organisation.find_by(iati_reference: reporting_org_reference)

    funding_org_element = legacy_activity.elements.detect { |element| element.name.eql?("participating-org") && element.attributes["role"].value.eql?("1") }
    if funding_org_element
      funding_org_reference = funding_org_element.attributes["ref"].value
      funding_organisation = Organisation.find_by(iati_reference: funding_org_reference)
      new_activity.funding_organisation_name = funding_organisation.name
      new_activity.funding_organisation_type = funding_organisation.organisation_type
      new_activity.funding_organisation_reference = funding_organisation.iati_reference
    end

    accountable_org_element = legacy_activity.elements.detect { |element| element.name.eql?("participating-org") && element.attributes["role"].value.eql?("2") }
    if accountable_org_element
      accountable_org_reference = accountable_org_element.attributes["ref"].value
      accountable_organisation = Organisation.find_by(iati_reference: accountable_org_reference)
      new_activity.accountable_organisation_name = accountable_organisation.name
      new_activity.accountable_organisation_type = accountable_organisation.organisation_type
      new_activity.accountable_organisation_reference = accountable_organisation.iati_reference
    end

    # There is no DP reference in the extending element. We must ask the user for it.
    new_activity.extending_organisation = delivery_partner

    implementing_org_elements = legacy_activity.elements.select { |element| element.name.eql?("participating-org") && element.attributes["role"].value.eql?("4") }
    implementing_org_elements.each do |org_element|
      new_activity.implementing_organisations << ImplementingOrganisation.create!(
        name: org_element.children.detect { |child| child.name.eql?("narrative") }.text,
        organisation_type: org_element.attributes["type"].value,
        activity: new_activity
      )
    end
  end

  private def add_transactions(legacy_activity:, roda_activity:)
    transaction_elements = legacy_activity.elements.select { |element| element.name.eql?("transaction") }
    transaction_elements.each do |transaction_element|
      currency = transaction_element.children.detect { |child| child.name.eql?("value") }.attributes["currency"]&.value || "GBP"
      date = transaction_element.children.detect { |child| child.name.eql?("transaction-date") }.attributes["iso-date"].value
      value = transaction_element.children.detect { |child| child.name.eql?("value") }.children.text
      transaction_type = transaction_element.children.detect { |child| child.name.eql?("transaction-type") }.attributes["code"].value
      disbursement_channel = if transaction_element.children.detect { |child| child.name.eql?("disbursement-channel") }.present?
        transaction_element.children.detect { |child| child.name.eql?("disbursement-channel") }.attributes["code"].value
      end

      description = if transaction_element.children.detect { |child| child.name.eql?("description") }.present?
        transaction_element.children.detect { |child| child.name.eql?("description") }.children.detect { |child| child.name.eql?("narrative") }.text
      else
        "Unknown description"
      end

      providing_organisation_name = transaction_element.children.detect { |child| child.name.eql?("provider-org") }.children.detect { |child| child.name.eql?("narrative") }.text
      providing_organisation_reference = transaction_element.children.detect { |child| child.name.eql?("provider-org") }.attributes["ref"].value

      receiving_organisation = transaction_element.children.detect { |child| child.name.eql?("receiver-org") }
      receiving_organisation_name = receiving_organisation.children.detect { |child| child.name.eql?("narrative") }.text
      receiving_organisation_reference = receiving_organisation.attributes["ref"].try(:value)
      receiving_organisation_type = receiving_organisation_type(attribute: receiving_organisation.attributes["type"], implementing_organisation: roda_activity.implementing_organisations.first)

      report = Report.find_by(fund: roda_activity.associated_fund, organisation: roda_activity.organisation)

      transaction = Transaction.new(
        description: normalize_string(description),
        transaction_type: transaction_type,
        currency: currency,
        date: date,
        value: value,
        parent_activity: roda_activity,
        disbursement_channel: disbursement_channel,
        providing_organisation_name: providing_organisation_name,
        providing_organisation_type: "10",
        providing_organisation_reference: providing_organisation_reference,
        receiving_organisation_name: receiving_organisation_name,
        receiving_organisation_type: receiving_organisation_type,
        receiving_organisation_reference: receiving_organisation_reference,
        ingested: true,
        report: report
      )

      transaction.save!
    end
  end

  private def add_budgets(legacy_activity:, roda_activity:)
    budget_elements = legacy_activity.elements.select { |element| element.name.eql?("budget") }
    budget_elements.each do |budget_element|
      status = budget_element.attributes["status"].value
      budget_type = budget_element.attributes["type"].value
      period_start_date = budget_element.children.detect { |child| child.name.eql?("period-start") }.attributes["iso-date"].value
      period_end_date = budget_element.children.detect { |child| child.name.eql?("period-end") }.attributes["iso-date"].value
      value = budget_element.children.detect { |child| child.name.eql?("value") }.children.text
      currency = budget_element.children.detect { |child| child.name.eql?("value") }.attributes["currency"]&.value || "GBP"

      budget = Budget.new(
        status: status,
        budget_type: budget_type,
        period_start_date: period_start_date,
        period_end_date: period_end_date,
        value: value,
        currency: currency,
        parent_activity: roda_activity,
        ingested: true
      )

      budget.save!
    end
  end

  private def add_planned_disbursements(legacy_activity:, roda_activity:)
    planned_disbursement_elements = legacy_activity.elements.select { |element| element.name.eql?("planned-disbursement") }
    planned_disbursement_elements.each do |planned_disbursement_element|
      planned_disbursement_type = planned_disbursement_element.attributes["type"].value
      value = planned_disbursement_element.children.detect { |child| child.name.eql?("value") }.children.text
      currency = planned_disbursement_element.children.detect { |child| child.name.eql?("value") }.attributes["currency"]&.value || "GBP"
      period_start_date = planned_disbursement_element.children.detect { |child| child.name.eql?("period-start") }.attributes["iso-date"].value
      period_end_date = planned_disbursement_element.children.detect { |child| child.name.eql?("period-end") }.attributes["iso-date"].value

      providing_organisation = planned_disbursement_element.children.detect { |child| child.name.eql?("provider-org") }
      providing_organisation_name = providing_organisation.children.detect { |child| child.name.eql?("narrative") }.text
      providing_organisation_type = providing_organisation_type(attribute: providing_organisation.attributes["type"])
      providing_organisation_reference = providing_organisation.attributes["ref"].try(:value)

      receiving_organisation = planned_disbursement_element.children.detect { |child| child.name.eql?("receiver-org") }
      receiving_organisation_name = receiving_organisation.children.detect { |child| child.name.eql?("narrative") }.text
      receiving_organisation_reference = receiving_organisation.attributes["ref"].try(:value)
      receiving_organisation_type = receiving_organisation_type(attribute: receiving_organisation.attributes["type"], implementing_organisation: roda_activity.implementing_organisations.first)

      report = Report.find_by(fund: roda_activity.associated_fund, organisation: roda_activity.organisation)

      planned_disbursement = PlannedDisbursement.new(
        planned_disbursement_type: planned_disbursement_type,
        period_start_date: period_start_date,
        period_end_date: period_end_date,
        value: value,
        currency: currency,
        parent_activity: roda_activity,
        providing_organisation_name: providing_organisation_name,
        providing_organisation_type: providing_organisation_type,
        providing_organisation_reference: providing_organisation_reference,
        receiving_organisation_name: receiving_organisation_name,
        receiving_organisation_type: receiving_organisation_type,
        receiving_organisation_reference: receiving_organisation_reference,
        report: report,
        ingested: true
      )
      planned_disbursement.save!
    end
  end

  private def providing_organisation_type(attribute:)
    return "10" if attribute.nil?
    attribute.value
  end

  private def receiving_organisation_type(attribute:, implementing_organisation:)
    return attribute.value unless attribute.nil?
    return implementing_organisation.organisation_type if implementing_organisation
    "0"
  end

  private def sector_category_code(sector_code:)
    sectors = all_sectors
    sector = sectors.find { |s| s.code == sector_code }
    return if sector.nil?
    sector.category
  end

  private def add_geography(legacy_activity:, new_activity:)
    recipient_region_element = legacy_activity.elements.detect { |element| element.name.eql?("recipient-region") }
    if recipient_region_element
      new_activity.geography = :recipient_region
      new_activity.recipient_region = recipient_region_element.attributes["code"].value
    end

    recipient_country_element = legacy_activity.elements.detect { |element| element.name.eql?("recipient-country") }
    if recipient_country_element
      new_activity.geography = :recipient_country
      new_activity.recipient_country = recipient_country_element.attributes["code"].value
    end
  end

  private def add_dates(legacy_activity:, new_activity:)
    planned_start_date_element = legacy_activity.elements.detect { |element| element.name.eql?("activity-date") && element.attributes["type"].value.eql?("1") }
    new_activity.planned_start_date = planned_start_date_element ? planned_start_date_element.attributes["iso-date"].value : nil
    actual_start_date_element = legacy_activity.elements.detect { |element| element.name.eql?("activity-date") && element.attributes["type"].value.eql?("2") }
    new_activity.actual_start_date = actual_start_date_element ? actual_start_date_element.attributes["iso-date"].value : nil
    planned_end_date_element = legacy_activity.elements.detect { |element| element.name.eql?("activity-date") && element.attributes["type"].value.eql?("3") }
    new_activity.planned_end_date = planned_end_date_element ? planned_end_date_element.attributes["iso-date"].value : nil
    actual_end_date_element = legacy_activity.elements.detect { |element| element.name.eql?("activity-date") && element.attributes["type"].value.eql?("4") }
    new_activity.actual_end_date = actual_end_date_element ? actual_end_date_element.attributes["iso-date"].value : nil
  end

  private def add_identifiers(legacy_activity:, new_activity:)
    new_activity.previous_identifier = legacy_activity.elements.detect { |element| element.name.eql?("iati-identifier") }.children.text
    new_activity.delivery_partner_identifier = legacy_activity.infer_internal_identifier
  end

  private def service_owner_organisation
    @service_owner_organisation ||= Organisation.find_by(service_owner: true)
  end

  private def normalize_string(string)
    CGI.unescape(string).strip
  end
end
