class ProjectPolicy < ActivityPolicy
  def index?
    true
  end

  def redact_from_iati?
    beis_user?
  end

  class Scope < Scope
    def resolve
      if user.organisation.service_owner?
        scope.all
      else
        scope.where(organisation: user.organisation)
      end
    end
  end
end
