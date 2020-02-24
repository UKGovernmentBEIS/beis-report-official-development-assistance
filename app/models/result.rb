Result = Struct.new(:success, :object) {
  def success?
    success == true
  end

  def failure?
    !success
  end
}
