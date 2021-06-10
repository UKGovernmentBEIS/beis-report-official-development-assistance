class IncomingTransfer < ApplicationRecord
  include Transfer

  def source_roda_identifier=(source_roda_identifier)
    activity = Activity.by_roda_identifier(source_roda_identifier)
    write_attribute(:source_id, activity&.id)
  end

  def source_roda_identifier
    source&.roda_identifier
  end
end
