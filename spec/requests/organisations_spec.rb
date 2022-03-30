require "iati_validator/xml"
RSpec.describe "XML Validation", type: :request do
  let(:organisation) { create(:delivery_partner_organisation) }
  let(:user) { create(:beis_user) }

  before do
    host! "test.local"
    login_as(user)
  end

  context "the downloaded XML conforms to IATI standards" do
    before { allow_any_instance_of(IATIValidator::XML).to receive(:valid?).and_return(true) }
    it "allows the XML to be downloaded without let or hindrance" do
      get "/exports/organisations/#{organisation.id}/iati/programme_activities.xml"
      expect(response).to be_ok
      expect(response.content_type).to eq("application/xml; charset=utf-8")
    end
  end

  context "the downloaded XML does not conform to IATI standards (has no activities)" do
    it "communicates the error to the user and alerts us as ops staff" do
      allow(Rollbar).to receive(:error)
      get "/exports/organisations/#{organisation.id}/iati/programme_activities.xml"
      expect(response).not_to be_ok
      expect(response.body).to include("Invalid XML generated")
      expect(response.body).to include("2:0: ERROR: Element &#39;iati-activities&#39;: Missing child element(s). Expected is ( iati-activity ).")
      expect(Rollbar).to have_received(:error).with IATIValidator::XML::InvalidError
    end
  end
end
