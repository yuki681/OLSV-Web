require "rails_helper"

RSpec.describe "Licenses", type: :system do
  let!(:license) { create(:license, id: 1, name: "Sample License", content: "Sample License ...") }
  let!(:notice) { create(:notice, content_ja: "注意事項の例", description_ja: "注意事項の説明") }
  let!(:license_notice) { create(:license_notice, license: license, notice: notice) }
  let!(:condition1) { create(:condition, name_ja: "条件の例1", description_ja: "条件の説明1") }
  let!(:condition2) { create(:condition, name_ja: "条件の例2", description_ja: "条件の説明2") }
  let!(:action) { create(:action, name_ja: "アクションの例") }
  let!(:permission) { create(:permission, license: license) }
  let!(:permission_action) { create(:permission_action, permission: permission, action: action) }
  let!(:condition_node_and) { create(:condition_node, node_type: "and_node", permission: permission) }
  let!(:condition_node_leaf1) { create(:condition_node, node_type: "leaf_node", permission: permission, parent_node: condition_node_and, condition: condition1) }
  let!(:condition_node_leaf2) { create(:condition_node, node_type: "leaf_node", permission: permission, parent_node: condition_node_and, condition: condition2) }

  context "visiting the index" do
    it "searches Sample and shows result" do
      visit "/"
      fill_in "q", with: "Sample"
      click_button "検索"

      expect(page).to have_text("「Sample」の検索結果：1件")
      expect(page).to have_link("Sample License", href: "/licenses/1")
    end

    it "searches NoExist and shows no result message" do
      visit "/"
      fill_in "q", with: "NoExist"
      click_button "検索"

      expect(page).to have_text("「NoExist」の検索結果：0件")
      expect(page).to have_text("該当するライセンスが見つかりませんでした。別のキーワードをお試しください。")
    end

    it "searches empty query and shows empty result message" do
      visit "/"
      fill_in "q", with: ""
      click_button "検索"

      expect(page).to have_text("「」の検索結果：0件")
      expect(page).to have_text("キーワードを入力してください。")
    end
  end

  context "visiting the show" do
    it "shows license details with conditions and notices" do
      visit "/licenses/1"

      expect(page).to have_text("アクションの例")
      expect(page).not_to have_text("条件の例")
      expect(page).not_to have_text("条件の説明")
      expect(page).to have_text("注意事項の例")
      expect(page).to have_text("注意事項の説明")
      expect(page).to have_text("Sample License ...")

      click_on "アクションの例"

      expect(page).to have_text("次のすべての条件が適用されます")
      expect(page).to have_text("条件の例1")
      expect(page).to have_text("条件の説明1")
      expect(page).to have_text("条件の例2")
      expect(page).to have_text("条件の説明2")
    end
  end
end
