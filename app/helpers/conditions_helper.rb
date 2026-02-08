module ConditionsHelper
  # ConditionNode を再帰で表示（Slimから呼ぶ）
  def render_condition_tree(node)
    return "" if node.nil?

    case node.node_type
    when "leaf_node"
      render "conditions/leaf", node: node
    when "and_node"
      render "conditions/node", node: node, text: "次のすべての条件が適用されます"
    when "or_node"
      render "conditions/node", node: node, text: "次のいずれかの条件が適用されます"
    else
      ""
    end
  end
end
