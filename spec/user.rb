class User
  attr_accessor :pod_id

  def initialize(pod_id)
    self.pod_id = pod_id
  end

  def api_client
    @client ||= DiasporaApi::InternalApi.new(pod_uri(pod_id))
  end

  def username
    @username ||= "test#{r_str}"
  end

  def diaspora_id
    "#{username}@#{@client.pod_host}"
  end

  def register
    api_client.register("test#{r_str}@test.local", username, "123456")
  end

  def remote_person(diaspora_id)
    api_client.find_or_fetch_person(diaspora_id).first
  end
end
