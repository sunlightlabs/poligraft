set :environment, (ENV['target'] || 'staging')

set :user, 'poligraft'
set :application, user
set :deploy_to, "/home/poligraft/www"

if environment == 'production'
  set :domain, "poligraft.com"
  set :num_workers, "6"
else
  set :domain, "staging.poligraft.org"
  set :num_workers, "6"
end

set :repository,  "git@github.com:sunlightlabs/poligraft.git"
set :scm, 'git'
set :use_sudo, false
set :deploy_via, :remote_cache

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
    run "#{shared_path}/kill_rogues.rb"
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

  task :bundle do
    bundler.symlink_vendor
    run("cd #{release_path} && export PATH=/home/#{user}/.gem/ruby/1.8/bin:$PATH && bundle install")
  end
end

after 'deploy:update_code' do
  bundler.bundle
  deploy.symlink_config
end