class Actual
  class CommentPolicy < ApplicationPolicy
    def update?
      ActualPolicy.new(user, record.commentable).update?
    end
  end
end
