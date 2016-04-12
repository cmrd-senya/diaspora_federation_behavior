class User
  attr_accessor :pod_id

  def initialize(pod_id)
    self.pod_id = pod_id
  end

  def api_client
    @client ||= DiasporaApi::InternalApi.new(pod_uri(pod_id))
  end

  def diaspora_id
    api_client.diaspora_id
  end

  def register
    api_client.register("test#{r_str}@test.local", "test#{r_str}", "123456")
  end

  def remote_person(diaspora_id)
    return unless people = api_client.find_or_fetch_person(diaspora_id)
    people.first
  end

  def add_to_first_aspect(remote_user)
    if person = remote_person(remote_user.diaspora_id)
      api_client.add_to_aspect(
        person["id"],
        api_client.aspects.first["id"]
      )
    end
  end

  def wait_for_notification(type, timeout=20)
    notifications = nil
    timeout.times do
      if notifications = api_client.notifications
        notifications.select! do |notification|
          notification[type]
        end
        break if notifications.count > 0
      end
      sleep(1)
    end

    notifications
  end
end
