RSpec.describe PagesController, "#show" do
  render_views

  %w[accessibility_statement cookie_statement privacy_policy terms_of_service].each do |page|
    context "GET /pages/#{page}" do
      subject { get :show, params: {id: page} }

      it { should have_http_status(200) }
      it { should render_template(page) }

      context "when user is logged in" do
        before do
          stub_user = create(:partner_organisation_user)
          allow(controller).to receive(:authenticated?).and_return(true)
          allow(controller).to receive(:current_user).and_return(stub_user)
        end

        it { should have_http_status(200) }
        it { should render_template(page) }
      end
    end
  end
end
