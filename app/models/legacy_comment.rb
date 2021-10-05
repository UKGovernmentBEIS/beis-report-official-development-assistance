# TODO: Remove this class/table once the data hase been migrated to
# the new "flexible" Comments table

class LegacyComment < ApplicationRecord
  belongs_to :owner, class_name: "User"
  belongs_to :activity
  belongs_to :report

  validates_presence_of :owner, :activity, :report
end
