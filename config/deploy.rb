set :environment, (ENV['target'] || 'staging')

set :user, 'poligraft'
set :application, user
set :deploy_to, "/home/poligraft/www"

if environment == 'production'
  set :domain, "poligraft.org"
else
  set :domain, "staging.poligraft.org"
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
  end
  
  task :symlink_config do
    run "ln -s #{shared_path}/config/keys.yml #{release_path}/config/keys.yml"
  end
  
  task :delayed_job do
    run "cd #{release_path} && RAILS_ENV=production script/delayed_job restart"
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
    run("cd #{release_path} && export PATH=/home/#{user}/.gem/ruby/1.8/bin:$PATH && bundle install --without test")
  end
end

after 'deploy:update_code' do
  bundler.bundle
  deploy.symlink_config
  deploy.delayed_job
end