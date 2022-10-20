class ServiceOwnerConstraint
  def self.matches?(request)
    user_id_from_session = request.session["warden.user.user.key"].try(:first).try(:first)
    return false if user_id_from_session.blank?

    user = User.find_by(id: user_id_from_session)
    user&.service_owner?
  end
end
