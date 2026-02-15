FactoryBot.define do
  factory :action do
    sequence(:source_id) { |n| "actions/#{n}" }
    sequence(:name_ja) { |n| "Sample Action #{n}" }
    description_ja { "説明" }
    schema_version { "0.1" }
    sequence(:uri) { |n| "https://example.com/actions/#{n}" }
    base_uri { "https://example.com/actions/" }
  end
end
