class Comment < ApplicationRecord
  include PublicActivity::Common

  belongs_to :owner, class_name: "User"
  belongs_to :activity
  belongs_to :report

  validates_presence_of :owner, :activity, :report
end
