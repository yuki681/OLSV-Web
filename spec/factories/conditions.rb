FactoryBot.define do
  factory :condition do
    sequence(:source_id) { |n| "condition/#{n}" }
    sequence(:name_ja) { |n| "Sample Condition #{n}" }
    condition_type { "restriction" }
    description_ja { "説明" }
    schema_version { "0.1" }
    sequence(:uri) { |n| "https://example.com/conditions/#{n}" }
    base_uri { "https://example.com/conditions/" }
  end
end
