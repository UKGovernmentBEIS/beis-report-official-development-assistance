class OutgoingTransfer < ApplicationRecord
  include Transfer

  def destination_roda_identifier=(destination_roda_identifier)
    activity = Activity.by_roda_identifier(destination_roda_identifier)
    write_attribute(:destination_id, activity&.id)
  end

  def destination_roda_identifier
    destination&.roda_identifier
  end
end
