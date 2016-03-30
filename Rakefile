require "rspec/core/rake_task"
require "diaspora_api"
require "./config"

def machine_off?(name)
  !`cd diaspora-replica && vagrant status #{name}`.include?("running")
end

def diaspora_up?(pod_nr)
  !DiasporaApi::Client.new(pod_uri(pod_nr)).nodeinfo_href.nil?
end

def launch_pod(pod_nr)
  if diaspora_up?(pod_nr)
    puts "Pod number #{pod_nr} is already up!"
  else
    sh "cd diaspora-replica/capistrano && bundle exec env SERVER_URL='#{pod_host(pod_nr)}' cap test diaspora:eye:start"
  end
end

def stop_pod(pod_nr)
  unless diaspora_up?(pod_nr)
    puts "Pod number #{pod_nr} isn't up!"
  else
    sh "cd diaspora-replica/capistrano && bundle exec env SERVER_URL='#{pod_host(pod_nr)}' cap test diaspora:eye:stop"
  end
end

def wait_pod_up(pod_nr, timeout=60)
  timeout.times do
    break if diaspora_up?(pod_nr)
    sleep 1
  end
  up = diaspora_up?(pod_nr)
  puts "failed to access pod number #{pod_nr} after #{timeout} seconds; there may be some problems with your configuration" unless up
  up
end

def deploy_app(pod_nr, revision)
  sh "cd diaspora-replica/capistrano && env BRANCH=#{revision} SERVER_URL='#{pod_host(pod_nr)}' bundle exec cap test deploy"
end

def install_vagrant_plugin(name)
  unless `cd diaspora-replica && vagrant plugin list`.include?(name)
    sh "cd diaspora-replica && vagrant plugin install #{name}"
  end
end

task :install_vagrant_requirements do
  install_vagrant_plugin("vagrant-hosts")
  install_vagrant_plugin("vagrant-group")
end

task :check_repository_clone do
  sh "mkdir -p diaspora-replica/src"
  `cd diaspora-replica/src && git status`
  unless $? == 0
    sh "git clone https://github.com/diaspora/diaspora.git diaspora-replica/src"
  else
    sh "cd diaspora-replica/src && git fetch --all"
  end
end

task :bring_up_testfarm => %i(install_vagrant_requirements check_repository_clone) do
  if machine_off?("pod1") || machine_off?("pod2")
    sh "cd diaspora-replica && vagrant group up testfarm"
  end
end

task :deploy_apps => :bring_up_testfarm do
  deploy_app(1, environment_configuration["pod1"]["revisions"].first)
  deploy_app(2, environment_configuration["pod1"]["revisions"].first)
end

task :launch_pods do
  if machine_off?("pod1") || machine_off?("pod2")
    puts "Required machines are halted! Aborting"
  else
    launch_pod(1)
    launch_pod(2)
    puts "Error encountered during pod launch" unless wait_pod_up(1) && wait_pod_up(2)
  end
end

task :stop_pods do
  stop_pod(1)
  stop_pod(2)
end

task :execute_tests => %i(bring_up_testfarm stop_pods) do
  environment_configuration["pod1"]["revisions"].each do |pod1_revision|
    puts "Deploying revision #{pod1_revision} on pod1"
    deploy_app(1, pod1_revision)
    launch_pod(1)
    environment_configuration["pod2"]["revisions"].each do |pod2_revision|
      puts "Deploying revision #{pod2_revision} on pod2"
      deploy_app(2, pod2_revision)
      launch_pod(2)

      unless wait_pod_up(1) && wait_pod_up(2)
        puts "Error encountered during pod launch, tests won't be run"
        exit -1
      else
        sh "bundle exec rake"
      end

      stop_pod(2)
    end
    stop_pod(1)
  end
end

task :clean do
  sh "cd diaspora-replica && vagrant group destroy testfarm"
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
