class ConditionNode < ApplicationRecord
  belongs_to :permission
  belongs_to :condition, optional: true

  belongs_to :parent_node, class_name: "ConditionNode", optional: true
  has_many :child_nodes, class_name: "ConditionNode", foreign_key: "parent_node_id", dependent: :destroy

  enum :node_type, { leaf_node: "LEAF", and_node: "AND", or_node: "OR" }
end
