RSpec.describe "layouts/_messages" do
  context "when passed a flash message with a string" do
    it "renders a simple message" do
      flash[:notice] = "This is a notice!"
      render
      expect(response).to include "This is a notice!"
    end
  end

  context "when passed a flash message with a hash" do
    it "renders a flash message with a hash that has title and errors keys" do
      flash[:notice] = {title: "The title", errors: {attribute: "Attribute", another_attribute: "Another attribute"}}
      render
      expect(response).to include "The title"
      expect(response).to include "Attribute"
      expect(response).to include "Another attribute"
    end

    it "renders nothing if the correct keys are missing" do
      flash[:notice] = {a_thing: "A thing", another_thing: "Another thing"}
      render
      expect(response).to eql ""
    end
  end
end
