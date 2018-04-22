require 'mina/rails'
require 'mina/git'
require 'mina/bundler'
require 'mina/puma'
require 'mina/scp'
require 'mina/rvm'    # for rvm support. (https://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

bundle_bin = '/home/zepang/.rvm/gems/ruby-2.4.1/wrappers//bundle'
environment = ENV['RAILS_ENV'] || 'staging'

if environment == 'production'
  user = 'zepang'
  branch = 'master'
  domain = '139.196.127.134'
  deploy_to = '/home/zepang/zpt-api-production'
else
  user = 'zepang'
  branch = File.read('.git/HEAD').gsub(/ref: refs\/heads\//, '').to_s
  branch = 'master'
  domain = '139.196.127.134'
  deploy_to = '/home/zepang/zpt-api-test'
end


set :application_name, 'zpt-api'
set :domain, domain
set :deploy_to, deploy_to
set :repository, 'git@github.com:zepang/zpt-api.git'
set :branch, branch
set :bundle_bin, bundle_bin

# Optional settings:
set :user, user          # Username in the server to SSH to.
set :port, 22           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
# set :shared_dirs, fetch(:shared_dirs, []).push('public/assets')
# set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml')
set :shared_files, fetch(:shared_files, []).push('.env')

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use', 'ruby-1.9.3-p125@default'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup => :environment do
  # command %{rbenv install 2.3.0 --skip-existing}
  scp_upload("#{Rails.root.join('.evn')}", "#{fetch(:deploy_to)}/shared/.env")
end

desc "Deploys the current version to the server."
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  # invoke :'git:ensure_pushed'
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_create'
    invoke :'rails:db_migrate'
    # invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      in_path(fetch(:current_path)) do
        command %{mkdir -p tmp/}
        command %{touch tmp/restart.txt}
        invoke :'puma:phased_restart'
      end
    end
  end

  # you can use `run :local` to run tasks on local machine before of after the deploy scripts
  # run(:local){ say 'done' }
end

# For help in making your deploy script, see the Mina documentation:
#
#  - https://github.com/mina-deploy/mina/tree/master/docs
