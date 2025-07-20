FROM ruby:3.3.7

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libmariadb-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    libvips \
    mariadb-client \
    curl \
    git \
    nodejs \
    python3 \
    cron \
    yarn && \
    rm -rf /var/lib/apt/lists/*

# Set workdir
ENV APP_PATH /usr/src/app
WORKDIR $APP_PATH

# Install gems
COPY Gemfile Gemfile.lock ./
RUN gem update --system && gem install bundler -v 2.5.21
RUN bundle config set force_ruby_platform true && \
    bundle config set build.nokogiri --use-system-libraries=false && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Precompile assets
RUN bundle exec rake assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-e", "production", "-b", "0.0.0.0", "-p", "3000"]
