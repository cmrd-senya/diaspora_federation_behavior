require "yaml"

def environment_configuration
  @environment_configuration ||= YAML::load(open("config.yml"))["configuration"]
end

def pod_uri(pod_nr)
  environment_configuration["pod#{pod_nr}"]["uri"]
end

def pod_host(pod_nr)
  URI.parse(pod_uri(pod_nr)).host
end
