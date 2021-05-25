RSpec.describe "Users can create a matched effort" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }
    let(:programme) { create(:programme_activity, extending_organisation: user.organisation) }

    let!(:project) { create(:project_activity, :with_report, organisation: user.organisation, parent: programme) }
    let!(:matched_effort_provider) { create(:matched_effort_provider) }

    before { authenticate!(user: user) }

    before do
      visit organisation_activity_path(project.organisation, project)

      click_on "Other funding"
      click_on t("page_content.matched_effort.button.create")
    end

    scenario "they can add a matched effort" do
      template = build(:matched_effort,
        organisation: matched_effort_provider,
        funding_type: "in_kind",
        category: "training",
        committed_amount: "1234",
        currency: "VND",
        exchange_rate: "0.0000305832",
        date_of_exchange_rate: Date.parse("2021-01-01"),
        notes: "Here are some notes")

      fill_in_matched_effort_form(template)

      expect(page).to have_content(t("action.matched_effort.create.success"))

      matched_effort = MatchedEffort.order("created_at ASC").last

      expect(matched_effort.organisation).to eq(matched_effort_provider)
      expect(matched_effort.funding_type).to eq("in_kind")
      expect(matched_effort.category).to eq("training")
      expect(matched_effort.committed_amount).to eq(1234.00)
      expect(matched_effort.currency).to eq("VND")
      expect(matched_effort.exchange_rate).to eq(0.0000305832)
      expect(matched_effort.date_of_exchange_rate).to eq(Date.parse("2021-01-01"))
      expect(matched_effort.notes).to eq("Here are some notes")

      within("table.implementing_organisations") do
        expect(page).to have_content(matched_effort_provider.name)
        expect(page).to have_content("In kind")
        expect(page).to have_content("Training")
        expect(page).to have_content("£1,234.00")
      end
    end

    scenario "creation is tracked with PublicActivity" do
      template = build(:matched_effort, organisation: matched_effort_provider)

      PublicActivity.with_tracking do
        fill_in_matched_effort_form(template)

        auditable_event = PublicActivity::Activity.last
        expect(auditable_event.key).to eq "matched_effort.create"
        expect(auditable_event.owner_id).to eq user.id
      end
    end

    scenario "they receive an error message when the category does not match the funding type" do
      template = build(:matched_effort,
        funding_type: "reciprocal",
        category: "staff_time",
        organisation: matched_effort_provider)

      fill_in_matched_effort_form(template)

      expect(page).to_not have_content(t("action.matched_effort.create.success"))
      expect(page).to have_content(
        t(
          "activerecord.errors.models.matched_effort.attributes.category.invalid",
          category: "Staff time",
          funding_type: "Reciprocal"
        )
      )
      expect(page.find(:xpath, "//input[@value='#{template.category}']").checked?).to be false
    end

    scenario "they recieve errors when required fields are left blank" do
      page.find(:xpath, "//input[@value='in_kind']").set(true)

      click_on t("default.button.submit")

      expect(page).to have_content("Organisation can't be blank")
      expect(page).to have_content("Category can't be blank")
    end
  end
end
