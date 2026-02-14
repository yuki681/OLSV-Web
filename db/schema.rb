# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_07_074718) do
  create_table "actions", force: :cascade do |t|
    t.text "base_uri"
    t.datetime "created_at", null: false
    t.text "description_ja"
    t.text "name_ja"
    t.string "schema_version"
    t.string "source_id", null: false
    t.datetime "updated_at", null: false
    t.text "uri"
    t.index ["source_id"], name: "index_actions_on_source_id", unique: true
  end

  create_table "condition_nodes", force: :cascade do |t|
    t.integer "condition_id"
    t.datetime "created_at", null: false
    t.string "node_type", null: false
    t.integer "parent_node_id"
    t.integer "permission_id", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["condition_id"], name: "index_condition_nodes_on_condition_id"
    t.index ["parent_node_id"], name: "index_condition_nodes_on_parent_node_id"
    t.index ["permission_id"], name: "index_condition_nodes_on_permission_id"
  end

  create_table "conditions", force: :cascade do |t|
    t.text "base_uri"
    t.string "condition_type", null: false
    t.datetime "created_at", null: false
    t.text "description_ja"
    t.text "name_ja"
    t.string "schema_version"
    t.string "source_id", null: false
    t.datetime "updated_at", null: false
    t.text "uri"
    t.index ["source_id"], name: "index_conditions_on_source_id", unique: true
  end

  create_table "license_notices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "license_id", null: false
    t.integer "notice_id", null: false
    t.datetime "updated_at", null: false
    t.index ["license_id", "notice_id"], name: "index_license_notices_on_license_id_and_notice_id", unique: true
    t.index ["license_id"], name: "index_license_notices_on_license_id"
    t.index ["notice_id"], name: "index_license_notices_on_notice_id"
  end

  create_table "licenses", force: :cascade do |t|
    t.text "base_uri"
    t.text "content"
    t.datetime "created_at", null: false
    t.text "description_ja"
    t.string "name", null: false
    t.string "schema_version"
    t.string "source_id", null: false
    t.text "summary_ja"
    t.datetime "updated_at", null: false
    t.text "uri"
    t.index ["source_id"], name: "index_licenses_on_source_id", unique: true
  end

  create_table "notices", force: :cascade do |t|
    t.text "base_uri"
    t.text "content_ja"
    t.datetime "created_at", null: false
    t.text "description_ja"
    t.string "schema_version"
    t.string "source_id", null: false
    t.datetime "updated_at", null: false
    t.text "uri"
    t.index ["source_id"], name: "index_notices_on_source_id", unique: true
  end

  create_table "permission_actions", force: :cascade do |t|
    t.integer "action_id", null: false
    t.datetime "created_at", null: false
    t.integer "permission_id", null: false
    t.datetime "updated_at", null: false
    t.index ["action_id"], name: "index_permission_actions_on_action_id"
    t.index ["permission_id", "action_id"], name: "index_permission_actions_on_permission_id_and_action_id", unique: true
    t.index ["permission_id"], name: "index_permission_actions_on_permission_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description_ja"
    t.integer "license_id", null: false
    t.text "summary_ja"
    t.datetime "updated_at", null: false
    t.index ["license_id"], name: "index_permissions_on_license_id"
  end

  add_foreign_key "condition_nodes", "condition_nodes", column: "parent_node_id"
  add_foreign_key "condition_nodes", "conditions"
  add_foreign_key "condition_nodes", "permissions"
  add_foreign_key "license_notices", "licenses"
  add_foreign_key "license_notices", "notices"
  add_foreign_key "permission_actions", "actions"
  add_foreign_key "permission_actions", "permissions"
  add_foreign_key "permissions", "licenses"
end
