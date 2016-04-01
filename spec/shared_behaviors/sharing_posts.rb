shared_examples_for "sharing posts" do
  before do
    result = user0.api_client.add_to_aspect(
      user0.remote_person(user1.diaspora_id)["id"],
      user0.api_client.aspects.first["id"]
    )

    expect(result).to be_truthy

    result = user1.api_client.add_to_aspect(
      user1.remote_person(user0.diaspora_id)["id"],
      user1.api_client.aspects.first["id"]
    )

    expect(result).to be_truthy
  end

  it "a private post is visible to a friend" do
    cnt = user1.api_client.stream.count
    msg = r_str
    resp = user0.api_client.post(msg, user0.api_client.aspects.first["name"])
    expect(resp).to be_truthy

    10.times do
      break if user1.api_client.stream.count == cnt+1
      sleep(1)
    end

    expect(user1.api_client.stream.count).to eq(cnt+1)
    expect(user1.api_client.stream[cnt]["text"]).to eq(msg)
  end
end
