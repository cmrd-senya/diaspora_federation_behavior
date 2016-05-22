require "shared_behaviors/sharing_posts"

shared_examples_for "user rename makes old ID inaccessible" do
  it "", upstream: false, rename_feature: true do
    user1_diaspora_id = @user1.api_client.diaspora_id
    expect(@user1.api_client.change_username("ivan", "bluepin7")).to be_truthy
    sleep(2)

    # check that the user can't login anymore with the old name
    expect(User.new(1).api_client.login("alice", "bluepin7")).to be_falsy

    # check that the user can login with the new name
    expect(User.new(1).api_client.login("ivan", "bluepin7")).to be_truthy

    # check there is no old user ID in user2's contacts
    expect(@user2.api_client.get_contacts.map { |cnt| cnt["handle"] }).not_to include(@user1.api_client.diaspora_id)

    # verify that user2 can't find old user ID by search
    # (actually this is true only for json queries, WEB UI shows the deleted user in search results anyway)
    expect(@user2.remote_person(user1_diaspora_id)).to be_nil

    # try to add user1 to aspects
    @user2.add_to_first_aspect(@user1) # this is allowed to pass in some cases still, but not generally a good thing

    # make sure user1's old ID wasn't added to aspects
    expect(@user2.api_client.get_contacts.map { |cnt| cnt["handle"] }).not_to include(@user1.api_client.diaspora_id)
  end
end

shared_examples_for "user rename updates contact references" do
  it "", upstream: false, rename_feature: true do
    # check there is the old user ID in user2's contacts
    expect(@user2.api_client.get_contacts.map { |cnt| cnt["handle"] }).to include(@user1.api_client.diaspora_id)

    expect(@user1.api_client.change_username("ivan", "bluepin7")).to be_truthy
    sleep(2)

    # check that the user can't login anymore with the old name
    expect(User.new(1).api_client.login("alice", "bluepin7")).to be_falsy

    new_user = User.new(1)
    # check that the user can login with the new name
    expect(new_user.api_client.login("ivan", "bluepin7")).to be_truthy

    new_id = new_user.api_client.diaspora_id
    # check there is the new user ID in user2's contacts
    expect(@user2.api_client.get_contacts.map { |cnt| cnt["handle"] }).to include(new_id)
  end
end

shared_examples_for "user still receives posts after changing his name" do
  metadata.merge!(upstream: false, rename_feature: true)

  before do
    expect(@user1.api_client.change_username("ivan", "bluepin7")).to be_truthy
    sleep(2)

    @new_user = User.new(1)
    # check that the user can login with the new name
    expect(@new_user.api_client.login("ivan", "bluepin7")).to be_truthy
  end

  it_behaves_like "a private post is visible to a friend" do
    let(:sender) { @user2 }
    let(:receiver) { @new_user }
  end
end
