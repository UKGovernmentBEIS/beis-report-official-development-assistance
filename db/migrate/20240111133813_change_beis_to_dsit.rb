class ChangeBeisToDsit < ActiveRecord::Migration[6.1]
  def up
    service_owner = Organisation.where(iati_reference: "GB-GOV-13").first
    if service_owner
      service_owner.iati_reference = "GB-GOV-26"
      service_owner.name = "DEPARTMENT FOR SCIENCE, INNOVATION AND TECHNOLOGY"
      service_owner.beis_organisation_reference = "DSIT"

      unless service_owner.save
        Rails.logger.error("Failed to save the changes to #{service_owner.name}: #{service_owner.errors.messages.inspect}")
      end
    end

    finance = Organisation.where(iati_reference: "GB-GOV-13-OPERATIONS").first
    if finance
      finance.iati_reference = "GB-GOV-26-OPERATIONS"
      finance.name = "DSIT FINANCE"
      finance.beis_organisation_reference = "DF"

      unless finance.save
        Rails.logger.error("Failed to save the changes to #{finance.name}: #{finance.errors.messages.inspect}")
      end
    end
  end

  def down
    service_owner = Organisation.where(iati_reference: "GB-GOV-26").first
    if service_owner
      service_owner.iati_reference = "GB-GOV-13"
      service_owner.name = "DEPARTMENT FOR BUSINESS, ENERGY & INDUSTRIAL STRATEGY"
      service_owner.beis_organisation_reference = "BEIS"

      unless service_owner.save
        Rails.logger.error("Failed to save the changes to #{service_owner.name}: #{service_owner.errors.messages.inspect}")
      end
    end

    finance = Organisation.where(iati_reference: "GB-GOV-26-OPERATIONS").first
    if finance
      finance.iati_reference = "GB-GOV-13-OPERATIONS"
      finance.name = "BEIS FINANCE"
      finance.beis_organisation_reference = "BF"

      unless finance.save
        Rails.logger.error("Failed to save the changes to #{finance.name}: #{finance.errors.messages.inspect}")
      end
    end
  end
end
