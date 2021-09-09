class FlexibleComment < ApplicationRecord
  belongs_to :commentable, polymorphic: true

  before_create :set_commentable_type

  validates :comment, presence: true

  def set_commentable_type
    self.commentable_type = commentable.class.to_s
  end
end
