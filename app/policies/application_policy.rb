class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user.administrator?
  end

  def show?
    user.administrator?
  end

  def create?
    user.administrator?
  end

  def new?
    create?
  end

  def update?
    user.administrator?
  end

  def edit?
    update?
  end

  def destroy?
    user.administrator?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
