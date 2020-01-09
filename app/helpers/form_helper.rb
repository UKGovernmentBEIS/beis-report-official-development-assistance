module FormHelper
  def list_of_organisations
    @list_of_organisations ||=
      [OpenStruct.new(name: "", id: ""), Organisation.sorted_by_name].flatten
  end

  def list_of_user_roles
    @list_of_user_roles ||= begin
      User.roles.map { |id, name| OpenStruct.new(id: id, name: I18n.t("activerecord.attributes.user.roles.#{name}")) }
    end
  end
end
