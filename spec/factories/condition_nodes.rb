FactoryBot.define do
  factory :condition_node do
    node_type { "leaf_node" }
    association :condition
    association :permission
    parent_node { nil }
  end
end
