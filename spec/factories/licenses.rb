FactoryBot.define do
  factory :license do
    sequence(:source_id) { |n| "licenses/#{n}" }
    sequence(:name) { |n| "Sample Licenses #{n}" }
    summary_ja { "要約" }
    description_ja { "説明" }
    content { "Sample License ..." }
    schema_version { "0.1" }
    sequence(:uri) { |n| "https://example.com/licenses/#{n}" }
    base_uri { "https://example.com/licenses/" }
  end
end
