require "application_system_test_case"

class LicensesTest < ApplicationSystemTestCase
  test "search shows query result text" do
    visit "/licenses?q=aaa"

    assert_text "「aaa」の検索結果"
  end
end
