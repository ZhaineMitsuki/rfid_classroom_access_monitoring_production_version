#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rake db:migrate

# Fix PostgreSQL sequences before seeding to prevent primary key conflicts
echo "Fixing PostgreSQL sequences..."
bundle exec rake db:fix_sequences

# Always run seeds - seeds.rb uses find_or_create_by which is safe for existing data
echo "Running database seeds..."
bundle exec rake db:seed 