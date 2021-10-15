class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :report

  before_create :set_commentable_type

  validates :body, presence: true

  def set_commentable_type
    self.commentable_type = commentable.class.to_s
  end

  def associated_activity
    case commentable_type
    when "Activity"
      commentable
    when "Refund"
      commentable.parent_activity
    when "Adjustment"
      commentable.parent_activity
    end
  end
end
