module FormHelper
  def list_of_organisations
    @list_of_organisations ||=
      [OpenStruct.new(name: "", id: ""), Organisation.all].flatten
  end
end
