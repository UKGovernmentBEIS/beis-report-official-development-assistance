class Adjustment
  class CommentPolicy < ApplicationPolicy
    def update?
      false
    end
  end
end
