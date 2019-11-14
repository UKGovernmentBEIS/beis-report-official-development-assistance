Result = Struct.new(:success) {
  def success?
    success == true
  end

  def failure?
    !success
  end
}
