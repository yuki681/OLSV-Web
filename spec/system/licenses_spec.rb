require "rails_helper"

RSpec.describe "Licenses", type: :system do
  it "search shows query result text" do
    visit "/licenses?q=aaa"

    expect(page).to have_text("「aaa」の検索結果")
  end
end
