require "spec_helper"

describe Assignment::UserResponse do

  it "has a factory" do
    expect(FactoryGirl.create(:user_response)).to be_valid
  end

  it 'requires a user_assignment' do
    expect(build :user_response, user_assignment_id: nil).not_to be_valid
  end

  it "should validate content" do
    expect(build :user_response, content: nil).not_to be_valid
  end
end