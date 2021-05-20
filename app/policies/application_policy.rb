class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError unless user

    @user = user
    @record = record
  end

  def new?
    create?
  end

  def edit?
    update?
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
    user.service_owner?
  end

  protected def delivery_partner_user?
    user.delivery_partner?
  end
end
