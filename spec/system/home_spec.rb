require "rails_helper"

RSpec.describe "Home", type: :system do
  it "visiting the index" do
    visit "/"

    expect(page).to have_selector("h1", text: "OSS License Simple Viewer Web")
  end
end
