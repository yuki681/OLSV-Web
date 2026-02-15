FactoryBot.define do
  factory :permission do
    summary_ja { "許可要約" }
    description_ja { "許可説明" }
    association :license
  end
end
