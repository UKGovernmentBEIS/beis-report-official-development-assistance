RSpec.describe HighVoltage::PagesController, "#show" do
  %w[accessibility_statement cookie_statement privacy_policy].each do |page|
    context "GET /pages/#{page}" do
      before do
        get :show, params: {id: page}
      end

      it { should respond_with(:success) }
      it { should render_template(page) }
    end
  end
end
