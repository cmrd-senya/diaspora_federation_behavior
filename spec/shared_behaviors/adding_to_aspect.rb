shared_examples_for "adding to aspect" do
  before do
    result = user0.api_client.add_to_aspect(
      user0.remote_person(user1.diaspora_id)["id"],
      user0.api_client.aspects.first["id"]
    )

    expect(result).to be_truthy
  end

  it "two users set up sharing correctly" do
    10.times do
      @notifications = user1.api_client.notifications
      expect(@notifications).not_to be_nil

      @notifications.select! do |notification|
        notification["started_sharing"]
      end
      break if @notifications.count > 0
      sleep(1)
    end

    expect(@notifications.count).to be > 0
    expect(@notifications.first["started_sharing"]["target_id"]).to eq(user1.remote_person(user0.diaspora_id)["id"])
  end

#  it "a private post is visible to a friend" do
#    msg = r_str
#    resp = user0.post(msg, user0.aspects.first["name"])
#    expect(resp).to eq("302")
#    
#  end
end
