class CreateLicenses < ActiveRecord::Migration[8.1]
  def change
    create_table :licenses do |t|
      t.string :source_id, null: false, index: { unique: true }
      t.string :name, null: false
      t.text :summary_ja
      t.text :description_ja
      t.text :content

      t.timestamps
    end

    create_table :notices do |t|
      t.string :source_id, null: false, index: { unique: true }
      t.text :content_ja
      t.text :description_ja

      t.timestamps
    end

    create_table :permissions do |t|
      t.text :summary_ja
      t.text :description_ja

      t.references :license, null: false, foreign_key: true
      t.timestamps
    end

    create_table :actions do |t|
      t.string :source_id, null: false, index: { unique: true }
      t.text :name_ja
      t.text :description_ja

      t.timestamps
    end

    create_table :license_notices do |t|
      t.references :license, null: false, foreign_key: true
      t.references :notice, null: false, foreign_key: true
      t.timestamps
    end
    add_index :license_notices, [:license_id, :notice_id], unique: true

    create_table :permission_actions do |t|
      t.references :permission, null: false, foreign_key: true
      t.references :action, null: false, foreign_key: true
      t.timestamps
    end
    add_index :permission_actions, [:permission_id, :action_id], unique: true
  end
end
