class Permission < ApplicationRecord
  belongs_to :license
  has_many :permission_actions, dependent: :destroy
  has_many :actions, through: :permission_actions
  has_many :condition_nodes, dependent: :destroy
  has_one :condition_head, -> { where(parent_node_id: nil) }, class_name: "ConditionNode", dependent: :destroy
end
