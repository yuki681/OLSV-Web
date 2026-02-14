# spec/tasks/import_oss_license_data_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "rake"
require "tmpdir"
require "json"

RSpec.describe "import:oss_license_data (integration)" do
  before(:all) do
    Rake.application = Rake::Application.new
    Rake.application.rake_require("tasks/import", [ Rails.root.join("lib").to_s ])
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task["import:oss_license_data"] }

  around do |example|
    original_env = ENV.to_hash
    begin

      example.run

    ensure
      ENV.replace(original_env)
    end
  end

  before do
    # FK がある想定で子→親の順に削除
    PermissionAction.delete_all
    ConditionNode.delete_all
    Permission.delete_all
    LicenseNotice.delete_all
    License.delete_all
    Action.delete_all
    Condition.delete_all
    Notice.delete_all
  end

  def write_json(path, obj)
    File.write(path, JSON.pretty_generate(obj))
  end

  def run_task!(dir_path:, on_missing_ref: nil)
    ENV["PATH"] = dir_path
    ENV["ON_MISSING_REF"] = on_missing_ref if on_missing_ref

    task.reenable

    stdout = StringIO.new
    stderr = StringIO.new
    begin
      orig_out, orig_err = $stdout, $stderr
      $stdout = stdout
      $stderr = stderr
      task.invoke
    ensure
      $stdout = orig_out
      $stderr = orig_err
    end

    { stdout: stdout.string, stderr: stderr.string }
  end

  # ---- dataset builder (your final JSON shape: array of { "data": ... }) ----
  def build_dataset(missing: {})
    # missing: { action: true/false, condition: true/false, notice: true/false }
    action_ref  = missing[:action] ? "act_missing" : "act_1"
    cond_ref_1  = missing[:condition] ? "cond_missing" : "cond_1"
    notice_ref  = missing[:notice] ? "notice_missing" : "notice_1"

    actions = if missing[:action]
      []
    else
      [
        {
          "data" => {
            "id" => "act_1",
            "name" => [ { "language" => "ja", "text" => "配布" } ],
            "description" => [ { "language" => "ja", "text" => "配布してよい" } ],
            "schemaVersion" => 1,
            "uri" => "https://example.invalid/actions/act_1",
            "baseUri" => "https://example.invalid/actions/"
          }
        }
      ]
    end

    conditions = [
      {
        "data" => {
          "id" => "cond_1",
          "conditionType" => "notice",
          "name" => [ { "language" => "ja", "text" => "著作権表示" } ],
          "description" => [ { "language" => "ja", "text" => "著作権表示を残す" } ],
          "schemaVersion" => 1,
          "uri" => "https://example.invalid/conditions/cond_1",
          "baseUri" => "https://example.invalid/conditions/"
        }
      }
    ]

    unless missing[:condition]
      conditions <<
        {
          "data" => {
            "id" => "cond_2",
            "conditionType" => "notice",
            "name" => [ { "language" => "ja", "text" => "著作権表示" } ],
            "description" => [ { "language" => "ja", "text" => "著作権表示を残す" } ],
            "schemaVersion" => 1,
            "uri" => "https://example.invalid/conditions/cond_2",
            "baseUri" => "https://example.invalid/conditions/"
          }
        }
    end

    notices = if missing[:notice]
      []
    else
      [
        { "data" =>
          {
            "id" => "notice_1",
            "content" => [ { "language" => "ja", "text" => "NOTICE本文" } ],
            "description" => [ { "language" => "ja", "text" => "NOTICEの説明" } ],
            "schemaVersion" => 1,
            "uri" => "https://example.invalid/notices/notice_1",
            "baseUri" => "https://example.invalid/notices/"
          }
        }
      ]
    end

    licenses = [
      {
        "data" => {
          "id" => "lic_1",
          "name" => "MIT",
          "summary" => [ { "language" => "ja", "text" => "要約" } ],
          "description" => [ { "language" => "ja", "text" => "説明" } ],
          "content" => "MIT License ...",
          "schemaVersion" => 1,
          "uri" => "https://example.invalid/licenses/lic_1",
          "baseUri" => "https://example.invalid/licenses/",
          "notices" => [ { "ref" => notice_ref } ],
          "permissions" => [
            {
              "summary" => [ { "language" => "ja", "text" => "許可要約" } ],
              "description" => [ { "language" => "ja", "text" => "許可説明" } ],
              "actions" => [ { "ref" => action_ref } ],
              "conditionHead" => {
                "type" => "AND",
                "children" => [
                  { "type" => "LEAF", "ref" => cond_ref_1 },
                  { "type" => "LEAF", "ref" => "cond_1" } # 片方は常に存在
                ]
              }
            }
          ]
        }
      }
    ]

    { actions:, conditions:, notices:, licenses: }
  end

  def with_tmp_dir(dataset)
    Dir.mktmpdir("oss_import_spec") do |dir|
      write_json(File.join(dir, "actions.json"), dataset[:actions])
      write_json(File.join(dir, "conditions.json"), dataset[:conditions])
      write_json(File.join(dir, "notices.json"), dataset[:notices])
      write_json(File.join(dir, "licenses.json"), dataset[:licenses])
      yield dir
    end
  end

  it "imports data and is idempotent (running twice does not create duplicates)" do
    dataset = build_dataset
    with_tmp_dir(dataset) do |dir|
      run_task!(dir_path: dir)

      expect(Action.count).to eq(1)
      expect(Condition.count).to eq(2)
      expect(Notice.count).to eq(1)
      expect(License.count).to eq(1)

      expect(LicenseNotice.count).to eq(1)
      expect(Permission.count).to eq(1)
      expect(PermissionAction.count).to eq(1)

      # condition tree: root(AND) + 2 leaves
      expect(ConditionNode.count).to eq(3)

      # run again
      run_task!(dir_path: dir)

      expect(Action.count).to eq(1)
      expect(Condition.count).to eq(2)
      expect(Notice.count).to eq(1)
      expect(License.count).to eq(1)

      # 子は置換なので増えない
      expect(LicenseNotice.count).to eq(1)
      expect(Permission.count).to eq(1)
      expect(PermissionAction.count).to eq(1)
      expect(ConditionNode.count).to eq(3)
    end
  end

  it "builds condition tree with correct node_type and sort_order (siblings are 0,1,...)" do
    dataset = build_dataset
    with_tmp_dir(dataset) do |dir|
      run_task!(dir_path: dir)

      perm = Permission.first
      root = ConditionNode.find_by!(permission_id: perm.id, parent_node_id: nil)

      expect(root.node_type).to eq("and_node")
      expect(root.sort_order).to eq(0)

      children = ConditionNode.where(permission_id: perm.id, parent_node_id: root.id).order(:sort_order).to_a
      expect(children.size).to eq(2)
      expect(children.map(&:node_type)).to eq(%w[leaf_node leaf_node])
      expect(children.map(&:sort_order)).to eq([ 0, 1 ])
    end
  end

  it "warns and continues on missing refs when ON_MISSING_REF=ignore (default behavior matches message)" do
    dataset = build_dataset(missing: { notice: true, action: true, condition: true })
    with_tmp_dir(dataset) do |dir|
      out = run_task!(dir_path: dir, on_missing_ref: "ignore")

      # マスタは欠けている（datasetで落としているので0）
      expect(Action.count).to eq(0)
      expect(Condition.count).to eq(1) # 片方は常に存在
      expect(Notice.count).to eq(0)

      # License / Permission は作られる（参照欠けても続行のため）
      expect(License.count).to eq(1)
      expect(Permission.count).to eq(1)

      # 参照欠損により join は作られない
      expect(LicenseNotice.count).to eq(0)
      expect(PermissionAction.count).to eq(0)

      # condition tree: root(AND) は作れるが、missing leaf はスキップされる -> leaf は1つだけ
      perm = Permission.first
      root = ConditionNode.find_by!(permission_id: perm.id, parent_node_id: nil)
      leaves = ConditionNode.where(permission_id: perm.id, parent_node_id: root.id).to_a
      expect(leaves.size).to eq(1)

      expect(out[:stderr]).to include("missing notice")
      expect(out[:stderr]).to include("missing action")
      expect(out[:stderr]).to include("missing condition")
      expect(out[:stderr]).to include("The ref is ignored because ON_MISSING_REF=ignore.")
    end
  end

  it "rolls back and aborts on missing refs when ON_MISSING_REF=rollback" do
    dataset = build_dataset(missing: { notice: true })
    with_tmp_dir(dataset) do |dir|
      expect { run_task!(dir_path: dir, on_missing_ref: "rollback") }
        .to raise_error(MissingRefError)

      # トランザクションごと戻る
      expect(License.count).to eq(0)
      expect(Permission.count).to eq(0)
      expect(ConditionNode.count).to eq(0)
      expect(LicenseNotice.count).to eq(0)
      expect(PermissionAction.count).to eq(0)

      expect(Action.count).to eq(0)
      expect(Condition.count).to eq(0)
      expect(Notice.count).to eq(0)
    end
  end
end
