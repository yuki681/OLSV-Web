FactoryBot.define do
  factory :permission_action do
    association :permission
    association :action
  end
end
