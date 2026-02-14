# frozen_string_literal: true

require "json"

namespace :import do
  desc <<~DESC
    Import OSS license data from a directory (idempotent).
    Usage:
      bin/rails import:oss_license_data PATH=/path/to/dir
    Options:
      ON_MISSING_REF=ignore   (default) : warn and continue
      ON_MISSING_REF=rollback           : rollback whole DB transaction and abort
  DESC

  task oss_license_data: :environment do
    base_dir = ENV.fetch("PATH")
    missing_mode = (ENV["ON_MISSING_REF"] || "ignore").downcase

    unless %w[ignore rollback].include?(missing_mode)
      raise ArgumentError, "ON_MISSING_REF must be 'ignore' or 'rollback' (given: #{missing_mode.inspect})"
    end

    paths = {
      actions:    File.join(base_dir, "actions.json"),
      conditions: File.join(base_dir, "conditions.json"),
      notices:    File.join(base_dir, "notices.json"),
      licenses:   File.join(base_dir, "licenses.json")
    }
    paths.each do |name, path|
      raise ArgumentError, "[import] #{name}.json not found: #{path}" unless File.exist?(path)
    end

    missing_ref = lambda do |type, ref, context|
      msg = "[import] missing #{type} ref=#{ref.inspect} (#{context})"
      if missing_mode == "rollback"
        raise MissingRefError, msg
      else
        warn msg + " The ref is ignored because ON_MISSING_REF=#{missing_mode}."
      end
    end

    ActiveRecord::Base.transaction do
      puts "[import] start (dir=#{base_dir}, on_missing_ref=#{missing_mode})"

      # actions
      actions_data = JSON.parse(File.read(paths[:actions]))
      puts "[import:actions] importing #{actions_data.size} items..."

      actions_data.each do |action_data|
        action = action_data.fetch("data")

        Action.upsert(
          {
            source_id: action.fetch("id"),
            name_ja: pick_ja_text(action["name"]),
            description_ja: pick_ja_text(action["description"]),
            schema_version: action["schemaVersion"],
            uri: action["uri"],
            base_uri: action["baseUri"]
          },
          unique_by: :source_id
        )
      end

      puts "[import:actions] done."

      # conditions
      conditions_data = JSON.parse(File.read(paths[:conditions]))
      puts "[import:conditions] importing #{conditions_data.size} items..."

      conditions_data.each do |condition_data|
        condition = condition_data.fetch("data")

        Condition.upsert(
          {
            source_id: condition.fetch("id"),
            condition_type: condition["conditionType"],
            name_ja: pick_ja_text(condition["name"]),
            description_ja: pick_ja_text(condition["description"]),
            schema_version: condition["schemaVersion"],
            uri: condition["uri"],
            base_uri: condition["baseUri"]
          },
          unique_by: :source_id
        )
      end

      puts "[import:conditions] done."

      # notices
      notices_data = JSON.parse(File.read(paths[:notices]))
      puts "[import:notices] importing #{notices_data.size} items..."
      notices_data.each do |notice_data|
        notice = notice_data.fetch("data")

        Notice.upsert(
          {
            source_id: notice.fetch("id"),
            content_ja: pick_ja_text(notice["content"]),
            description_ja: pick_ja_text(notice["description"]),
            schema_version: notice["schemaVersion"],
            uri: notice["uri"],
            base_uri: notice["baseUri"]
          },
          unique_by: :source_id
        )
      end

      puts "[import:notices] done."

      # 参照キャッシュ（licenses の前に作る）
      action_id_by_ext = Action.pluck(:source_id, :id).to_h
      cond_id_by_ext   = Condition.pluck(:source_id, :id).to_h
      notice_id_by_ext = Notice.pluck(:source_id, :id).to_h

      # licenses（冪等：Licenseは upsert、子は毎回置換）
      licenses_data = JSON.parse(File.read(paths[:licenses]))
      puts "[import:licenses] importing #{licenses_data.size} items and regarding data..."

      licenses_data.each do |license_data|
        license = license_data.fetch("data")

        ext_id = license.fetch("id")

        # 1) License 自体を upsert（source_id がユニークである前提）
        License.upsert(
          {
            source_id: ext_id,
            name: license.fetch("name"),
            summary_ja: pick_ja_text(license["summary"]),
            description_ja: pick_ja_text(license["description"]),
            content: license["content"],
            schema_version: license["schemaVersion"],
            uri: license["uri"],
            base_uri: license["baseUri"]
          },
          unique_by: :source_id
        )

        lic = License.find_by!(source_id: ext_id)

        # 2) 子テーブルを「置換」する（これで再実行しても重複しない）
        replace_license_children!(lic.id)

        # license_notices
        (license["notices"] || []).each do |ref|
          n_ext = ref.fetch("ref")
          nid = notice_id_by_ext[n_ext]
          if nid.nil?
            missing_ref.call("notice", n_ext, "license=#{lic.source_id} license_notices")
            next
          end
          LicenseNotice.create!(license_id: lic.id, notice_id: nid)
        end

        # permissions（毎回作り直す：permission_id が変わっても整合が取れる）
        (license["permissions"] || []).each do |p|
          perm = Permission.create!(
            license_id: lic.id,
            summary_ja: pick_ja_text(p["summary"]),
            description_ja: pick_ja_text(p["description"]),
          )

          # permission_actions
          (p["actions"] || []).each do |aref|
            a_ext = aref.fetch("ref")
            aid = action_id_by_ext[a_ext]
            if aid.nil?
              missing_ref.call("action", a_ext, "license=#{lic.source_id} permission_id=#{perm.id} permission_actions")
              next
            end
            PermissionAction.create!(permission_id: perm.id, action_id: aid)
          end

          # condition tree
          head = p["conditionHead"]
          if head
            build_condition_tree!(
              permission_id: perm.id,
              parent_node_id: nil,
              node: head,
              cond_id_by_ext: cond_id_by_ext,
              on_missing_ref: missing_ref,
              license_source_id: lic.source_id
            )
          end
        end
      end

      puts "[import:licenses] done."

      # FTS は後で有効化する前提のため、このままコメントアウト
      # Rake::Task["import:rebuild_fts"].invoke

      puts "[import] done"
    rescue MissingRefError => e
      warn e.message
      raise
    end
  end

  class MissingRefError < StandardError; end

  # ---- helpers ----
  def pick_ja_text(arr)
    return nil unless arr.is_a?(Array)
    ja = arr.find { |x| x["language"] == "ja" }
    (ja && ja["text"]) || nil
  end

  # License配下を全部消して作り直す（冪等性の核）
  #
  # NOTE:
  # - dependent: :destroy が付いていても、ここでは速度と確実性のため delete_all を明示
  # - FK制約がある場合は「子→親」の順番で消す
  def replace_license_children!(license_id)
    perm_ids = Permission.where(license_id: license_id).pluck(:id)

    # permission配下
    PermissionAction.where(permission_id: perm_ids).delete_all
    ConditionNode.where(permission_id: perm_ids).delete_all
    Permission.where(id: perm_ids).delete_all

    # license直下
    LicenseNotice.where(license_id: license_id).delete_all
  end

  def build_condition_tree!(permission_id:, parent_node_id:, node:, cond_id_by_ext:, on_missing_ref:, license_source_id:, sort_order: 0)
    t = node.fetch("type")

    if t == "LEAF"
      cond_ref = node.fetch("ref")
      cid = cond_id_by_ext[cond_ref]
      if cid.nil?
        on_missing_ref.call("condition", cond_ref, "license=#{license_source_id} permission_id=#{permission_id} condition_tree")
        return nil
      end

      ConditionNode.create!(
        permission_id: permission_id,
        parent_node_id: parent_node_id,
        node_type: "LEAF",
        condition_id: cid,
        sort_order: sort_order
      )

    elsif t == "AND" || t == "OR"
      cn = ConditionNode.create!(
        permission_id: permission_id,
        parent_node_id: parent_node_id,
        node_type: t,
        condition_id: nil,
        sort_order: sort_order
      )

      (node["children"] || []).each_with_index do |child, idx|
        build_condition_tree!(
          permission_id: permission_id,
          parent_node_id: cn.id,
          node: child,
          cond_id_by_ext: cond_id_by_ext,
          on_missing_ref: on_missing_ref,
          license_source_id: license_source_id,
          sort_order: idx
        )
      end

    else
      raise ArgumentError, "unknown condition node type: #{t.inspect}"
    end
  end
end
