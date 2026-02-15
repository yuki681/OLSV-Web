FactoryBot.define do
  factory :license_notice do
    association :license
    association :notice
  end
end
