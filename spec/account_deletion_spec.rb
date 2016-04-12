require "user"
require "spec_helper"
require "common_expectations"

def delete_user1_and_verify
  @user1.api_client.delete_account("bluepin7")
  expect(User.new(1).api_client.login("alice", "bluepin7")).to be_falsy
  sleep 3 # wait pod1 to process the account deletion job. This must be done in a more robust way
  expect(@user2.api_client.get_contacts.map { |cnt| cnt["handle"] }).not_to include(@user1.api_client.diaspora_id)
  @user2.add_to_first_aspect(@user1) # this is allowed to pass in some cases still, but not generally a good thing
  expect(@user2.api_client.get_contacts.map { |cnt| cnt["handle"] }).not_to include(@user1.api_client.diaspora_id)
end

describe "account deletion feature" do
  before do
    @user1 = User.new(1)
    expect(@user1.api_client.login("alice", "bluepin7")).to be_truthy
    @user2 = User.new(2)
    expect(@user2.api_client.login("alice", "bluepin7")).to be_truthy
  end

  context "with two users" do
    before do
      @user1.add_to_first_aspect(@user2)
      @user2.add_to_first_aspect(@user1)
    end

    it "informs friends of the account deletion" do
      expect_for_sharing_notification(@user1, @user2)
      expect_for_sharing_notification(@user2, @user1)

      delete_user1_and_verify
    end
  end

  context "with a one-way sharing" do
    before do
      @user2.add_to_first_aspect(@user1)
    end

    it "informs friends of the account deletion" do
      expect_for_sharing_notification(@user1, @user2)

      delete_user1_and_verify
    end
  end

  context "with a one-way sharing (opposite)" do
    before do
      @user1.add_to_first_aspect(@user2)
    end

    it "informs friends of the account deletion" do
      expect_for_sharing_notification(@user2, @user1)

      delete_user1_and_verify
    end
  end

  context "without sharing" do
    it "one can't find deleted user" do
      @user1.api_client.diaspora_id # prefetch lazy diaspora_id because the user be frozen after the act deletion
      delete_user1_and_verify

      expect(@user2.remote_person(@user1.diaspora_id)).to be_nil
    end

    it "one can't add deleted user of other pod even if he prefetched the profile before" do
      expect(@user2.remote_person(@user1.diaspora_id)).not_to be_nil # prefetch the profile

      delete_user1_and_verify
    end
  end
end
