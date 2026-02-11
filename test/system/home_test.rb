require "application_system_test_case"

class HommeTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit root_url

    assert_selector "h1", text: "OSS License Simple Viewer"
  end
end
