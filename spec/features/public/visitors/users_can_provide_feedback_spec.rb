RSpec.feature "Users can provide feedback" do
  scenario "by following a link to the feedback form in the site phase banner" do
    visit root_path

    expect(page).to have_link("feedback", href: "https://docs.google.com/forms/d/e/1FAIpQLSfk9abTLRNZdB9tPdtoF_t_1z7q6uPQiZks8NfzGeqg-8UQtQ/viewform")
  end
end
