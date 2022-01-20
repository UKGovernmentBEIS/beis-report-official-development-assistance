RSpec.describe "layouts/application" do
  # standard:disable Lint/ConstantDefinitionInBlock
  class ActionView::TestCase::TestController
    include Auth

    def current_user
      nil
    end
  end
  # standard:enable Lint/ConstantDefinitionInBlock

  it "shows the meta tags when ROBOT_NOINDEX is set to true" do
    ClimateControl.modify ROBOT_NOINDEX: "true" do
      render
      expect(response).to include("<meta content='noindex' name='robots'>")
      expect(response).to include("<meta content='noindex' name='googlebot'>")
    end
  end

  it "does not show the meta tags when ROBOT_NOINDEX is set to false" do
    ClimateControl.modify ROBOT_NOINDEX: "false" do
      render
      expect(response).to_not include("<meta content='noindex' name='robots'>")
      expect(response).to_not include("<meta content='noindex' name='googlebot'>")
    end
  end
end
