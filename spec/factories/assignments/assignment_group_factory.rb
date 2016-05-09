FactoryGirl.define do
  factory :assignment_group, class: Assignment::AssignmentGroup do
    title { Faker::Lorem.sentence }
    desc_md { Faker::Lorem.paragraph }
    association :owner, factory: :admin, strategy: :build

    trait :with_template do
      association :assignment_group_template, :with_surveys
    end

    # also creates tables
    trait :with_full_template do
      association :assignment_group_template, :with_full_surveys
    end
  end
end
