class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :report

  before_create :set_commentable_type

  validates :body, presence: true

  scope :with_commentables, -> {
    joins("left outer join activities on activities.id = comments.commentable_id AND comments.commentable_type = 'Activity'")
      .joins("left outer join transactions AS refunds on refunds.id = comments.commentable_id AND comments.commentable_type = 'Refund'")
      .joins("left outer join transactions AS adjustments on adjustments.id = comments.commentable_id AND comments.commentable_type = 'Adjustment'")
      .joins("left outer join transactions AS actuals on actuals.id = comments.commentable_id AND comments.commentable_type = 'Actuals'")
  }
  scope :for_activity, ->(activity) {
    with_commentables
      .where("refunds.parent_activity_id = :activity_id OR
              adjustments.parent_activity_id = :activity_id OR
              activities.id = :activity_id OR
              actuals.id = :activity_id", {activity_id: activity.id})
  }

  def set_commentable_type
    self.commentable_type = commentable.class.to_s
  end

  def associated_activity
    return commentable if commentable_type == "Activity"

    # Expected other values of commentable_type Refund, Adjustment and Actual
    commentable.parent_activity
  end
end
