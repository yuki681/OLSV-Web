FactoryBot.define do
  factory :notice do
    sequence(:source_id) { |n| "notice/#{n}" }
    content_ja { "NOTICE本文" }
    description_ja { "NOTICEの説明" }
    schema_version { "0.1" }
    sequence(:uri) { |n| "https://example.com/notices/#{n}" }
    base_uri { "https://example.com/notices/" }
  end
end
