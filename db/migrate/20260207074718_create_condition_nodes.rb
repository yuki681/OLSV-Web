class CreateConditionNodes < ActiveRecord::Migration[8.1]
  def change
    create_table :condition_nodes do |t|
      t.string :node_type, null: false
      t.integer :sort_order, null: false, default: 0

      t.references :permission, null: false, foreign_key: true
      t.references :condition, foreign_key: true
      t.references :parent_node, foreign_key: { to_table: :condition_nodes }

      t.timestamps
    end

    create_table :conditions do |t|
      t.string :source_id, null: false, index: { unique: true }
      t.string :condition_type, null: false
      t.text :name_ja
      t.text :description_ja

      t.timestamps
    end
  end
end
