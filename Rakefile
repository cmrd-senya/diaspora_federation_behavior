require "rspec/core/rake_task"
require "diaspora_api"
require "logger"
require "./config"

def logger
  return @logger unless @logger.nil?
  file = File.new("log/#{Time.now.utc.to_i}.log", "w")
  file.sync = true
	@logger = Logger.new(file)
#	@logger = Logger.new(STDOUT)
  @logger.datetime_format = "%H:%M:%S"
	@logger.level = Logger::INFO
	@logger
end

def pipesh(cmd)
  logger.info("Launching \"#{cmd}\"")
  IO.popen (cmd) do |f|
    while str = f.gets
      logger.info(str.chomp)
    end
  end
  $?
end

def report_error(str)
  logger.error(str)
  puts(str)
end

def report_info(str)
  logger.info(str)
  puts(str)
end

def machine_off?(name)
  !`cd diaspora-replica && vagrant status #{name}`.include?("running")
end

def diaspora_up?(pod_nr)
  !DiasporaApi::Client.new(pod_uri(pod_nr)).nodeinfo_href.nil?
end

def launch_pod(pod_nr)
  if diaspora_up?(pod_nr)
    logger.info "Pod number #{pod_nr} is already up!"
  else
    pipesh "cd diaspora-replica/capistrano && bundle exec env SERVER_URL='#{pod_host(pod_nr)}' cap test diaspora:eye:start"
    $?
  end
end

def stop_pod(pod_nr)
  unless diaspora_up?(pod_nr)
    logger.info "Pod number #{pod_nr} isn't up!"
  else
    pipesh "cd diaspora-replica/capistrano && bundle exec env SERVER_URL='#{pod_host(pod_nr)}' cap test diaspora:eye:stop"
  end
end

def wait_pod_up(pod_nr, timeout=60)
  timeout.times do
    break if diaspora_up?(pod_nr)
    sleep 1
  end
  up = diaspora_up?(pod_nr)
  logger.error "failed to access pod number #{pod_nr} after #{timeout} seconds; there may be some problems with your configuration" unless up
  up
end

def deploy_app(pod_nr, revision)
  pipesh "cd diaspora-replica/capistrano && env BRANCH=#{revision} SERVER_URL='#{pod_host(pod_nr)}' bundle exec cap test deploy"
  $?
end

def install_vagrant_plugin(name)
  unless `cd diaspora-replica && vagrant plugin list`.include?(name)
    pipesh "cd diaspora-replica && vagrant plugin install #{name}"
  end
end

task :install_vagrant_requirements do
  install_vagrant_plugin("vagrant-hosts")
  install_vagrant_plugin("vagrant-group")
end

task :check_repository_clone do
  pipesh "mkdir -p diaspora-replica/src"
  `cd diaspora-replica/src && git status`
  unless $? == 0
    pipesh "git clone https://github.com/diaspora/diaspora.git diaspora-replica/src"
  else
    pipesh "cd diaspora-replica/src && git fetch --all"
  end
end

task :bring_up_testfarm => %i(install_vagrant_requirements check_repository_clone) do
  if machine_off?("pod1") || machine_off?("pod2")
    report_info "Bringing up test environment"
    pipesh "cd diaspora-replica && vagrant group up testfarm"
  end
end

task :deploy_apps => :bring_up_testfarm do
  deploy_app(1, environment_configuration["pod1"]["revisions"].first)
  deploy_app(2, environment_configuration["pod1"]["revisions"].first)
end

task :launch_pods do
  if machine_off?("pod1") || machine_off?("pod2")
    logger.info "Required machines are halted! Aborting"
  else
    launch_pod(1)
    launch_pod(2)
    report_error "Error encountered during pod launch" unless wait_pod_up(1) && wait_pod_up(2)
  end
end

task :stop_pods do
  stop_pod(1)
  stop_pod(2)
end

def deploy_and_launch(pod_nr, revision)
  report_info "Deploying revision #{revision} on pod#{pod_nr}"
  unless deploy_app(pod_nr, revision) == 0
    report_error "Failed to deploy pod#{pod_nr} with revision #{revision}"
    return false
  end
  unless launch_pod(pod_nr) == 0
    report_error "Failed to launch pod #{pod_nr}"
    return false
  end
  return true
end

task :execute_tests => %i(bring_up_testfarm stop_pods) do
  environment_configuration["pod1"]["revisions"].each do |pod1_revision|
    next unless deploy_and_launch(1, pod1_revision)
    environment_configuration["pod2"]["revisions"].each do |pod2_revision|
      next unless deploy_and_launch(2, pod2_revision)

      unless wait_pod_up(1) && wait_pod_up(2)
        report_error "Error encountered during pod launch, tests won't be run"
        exit -1
      else
        if pipesh("bundle exec rake") == 0
          report_info "Test suite finished correctly"
        else
          report_error "Test suite failed"
        end
      end

      stop_pod(2)
    end
    stop_pod(1)
  end
end

task :clean do
  pipesh "cd diaspora-replica && vagrant group destroy testfarm"
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
