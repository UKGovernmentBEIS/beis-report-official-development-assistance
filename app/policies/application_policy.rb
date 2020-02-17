class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError unless user

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
      raise Pundit::NotAuthorizedError unless user

      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end

  protected def beis_user?
    user.organisation.service_owner?
  end
end
