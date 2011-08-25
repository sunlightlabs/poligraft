$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"
set :rvm_ruby_string, '1.9.2'
set :rvm_type, :user

set :environment, (ENV['target'] || 'staging')

set :user, 'poligraft'
set :application, user
set :deploy_to, "/projects/poligraft/www"

if environment == 'production'
  set :domain, "ec2-184-72-134-174.compute-1.amazonaws.com"
  set :num_workers, "6"
else
  set :domain, "staging.poligraft.org"
  set :num_workers, "6"
end

set :repository,  "git@github.com:sunlightlabs/poligraft.git"
set :scm, 'git'
set :use_sudo, false
set :deploy_via, :remote_cache
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"


role :web, domain
role :app, domain
role :db,  domain, :primary => true

after "deploy", "deploy:cleanup"

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
    deploy.delayed_job
  end

  task :delayed_job do
    run "cd #{current_path} && RAILS_ENV=production script/delayed_job stop"
    sleep 2
    #run "#{shared_path}/kill_rogues.rb"
    run "cd #{current_path} && RAILS_ENV=production script/delayed_job -n #{num_workers} start"
  end

  task :symlink_config do
    run "ln -s #{shared_path}/config/keys.yml #{release_path}/config/keys.yml"
    run "ln -s #{shared_path}/config/mail.yml #{release_path}/config/mail.yml"
  end
end

namespace :bundler do
  task :install do
    run("gem install bundler")
  end

  task :symlink_vendor do
    shared_gems = "#{shared_path}/vendor/gems"
    release_gems = "#{release_path}/vendor/gems"
    run("mkdir -p #{shared_gems} && mkdir -p #{release_gems} && rm -rf #{release_gems} && ln -s #{shared_gems} #{release_gems}")
  end

end

namespace :unicorn do
  desc "start unicorn"
  task :start, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && unicorn_rails -c #{current_path}/config/unicorn.rb -E production -D"
  end
  desc "stop unicorn"
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "kill `cat #{unicorn_pid}`"
  end
  desc "graceful stop unicorn"
  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "kill -s QUIT `cat #{unicorn_pid}`"
  end
  desc "reload unicorn"
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "kill -s USR2 `cat #{unicorn_pid}`"
  end
end

after "deploy", "deploy:cleanup"
after "deploy:update_code", "deploy:symlink_config"
after "deploy:restart", "unicorn:reload"
