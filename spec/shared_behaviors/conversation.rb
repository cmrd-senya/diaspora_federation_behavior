def wait_block(timeout)
  res = nil
  timeout.times do
    res = yield
    break if res
    sleep(1)
  end
  res
end

def post_comment(user, post_id)
  res, data = user.api_client.comment("comment text", post_id)
  expect(res).to be_truthy
  expect(data).to have_key("guid")
  return data["guid"], data["id"]
end

def expect_comment(user, post_guid, comment_guid)
  res = wait_block(15) do
    res = user.api_client.get_path("/posts/#{post_guid}/comments")
    res if res.count > 0
  end
  expect(res).to be_truthy
  expect(res.last).to have_key("guid")
  expect(res.last["guid"]).to eq(comment_guid)
end

def expect_no_comments(user, post_guid)
  res = wait_block(15) do
    res = user.api_client.get_path("/posts/#{post_guid}/comments")
    res if res.count == 0
  end
  expect(res).to be_truthy
end

shared_examples_for "conversation with a post and comments" do
  it "" do
    res, data = @user1.api_client.post("hello, friend", aspect)
    expect(res).to be_truthy
    expect(data).to have_key("guid")
    post_id_on_pod1 = data["id"]
    post_guid = data["guid"]

    res = wait_block(15) do
      @user2.api_client.get_path("/posts/#{post_guid}")
    end
    expect(res).to be_truthy
    expect(res).to have_key("id")
    post_id_on_pod2 = res["id"]

    comment_guid, comment_id = post_comment(@user2, post_id_on_pod2)
    expect_comment(@user1, post_guid, comment_guid)

    another_comment_guid, another_comment_id = post_comment(@user1, post_id_on_pod1)
    expect_comment(@user2, post_guid, another_comment_guid)

    expect(@user1.api_client.retract_entity("comment", another_comment_id)).to be_truthy
    expect(@user2.api_client.retract_entity("comment", comment_id)).to be_truthy
    expect_no_comments(@user1, post_guid)
    expect_no_comments(@user2, post_guid)

    expect(@user1.api_client.retract_entity("post", post_id_on_pod1)).to be_truthy
    res = wait_block(15) do
      @user2.api_client.get_path("/posts/#{post_guid}").nil?
    end
    expect(res).to be_truthy
  end
end

shared_examples_for "private and public conversation with a post and comments" do
  context "public" do
    it_behaves_like "conversation with a post and comments" do
      let(:aspect) { "public" }
    end
  end

  context "private" do
    it_behaves_like "conversation with a post and comments" do
      let(:aspect) { @user1.api_client.aspects.first["name"] }
    end
  end
end
