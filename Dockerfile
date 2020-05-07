# ------------------------------------------------------------------------------
# base
# ------------------------------------------------------------------------------
FROM ruby:2.6.3 AS base
LABEL maintainer="rails@dxw.com"

RUN apt-get update && apt-get install -qq -y \
  build-essential \
  libpq-dev \
  firefox-esr \
  --fix-missing --no-install-recommends

ARG gecko_driver_version=0.26.0

RUN wget https://github.com/mozilla/geckodriver/releases/download/v$gecko_driver_version/geckodriver-v$gecko_driver_version-linux64.tar.gz
RUN tar -xvzf  geckodriver-v$gecko_driver_version-linux64.tar.gz
RUN rm geckodriver-v$gecko_driver_version-linux64.tar.gz
RUN chmod +x geckodriver
RUN mv geckodriver* /usr/local/bin

ENV APP_HOME /app
ENV DEPS_HOME /deps

ARG RAILS_ENV
ENV RAILS_ENV ${RAILS_ENV:-production}
ENV NODE_ENV ${RAILS_ENV:-production}

# ------------------------------------------------------------------------------
# dependencies
# ------------------------------------------------------------------------------
FROM base AS dependencies

# Set up install environment
RUN mkdir -p ${DEPS_HOME}
WORKDIR ${DEPS_HOME}
# End

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
        && apt-get install -y nodejs

# Install Ruby dependencies
COPY Gemfile ${DEPS_HOME}/Gemfile
COPY Gemfile.lock ${DEPS_HOME}/Gemfile.lock

RUN gem update --system 3.0.3
RUN gem update rake 13.0.1
RUN gem install bundler

RUN bundle config set frozen 'true'

# Configure bundler for both test and production
RUN bundle config set without 'development'
RUN bundle config set deployment 'true'
RUN bundle config
RUN bundle install --retry 3 --jobs 2
# end

# Install JavaScript dependencies
COPY package.json ${DEPS_HOME}/package.json
COPY package-lock.json ${DEPS_HOME}/package-lock.json

RUN npm set progress=false && npm config set depth 0
RUN npm install
#end

# ------------------------------------------------------------------------------
# web
# ------------------------------------------------------------------------------
FROM dependencies AS web

# Set up install environment
RUN mkdir -p ${APP_HOME}
WORKDIR ${APP_HOME}
# end

COPY . ${APP_HOME}

# This must be ordered before rake assets:precompile
RUN cp -R $DEPS_HOME/node_modules $APP_HOME/node_modules
RUN cp -R $DEPS_HOME/node_modules/govuk-frontend/govuk/assets $APP_HOME/app/assets

RUN RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE="super secret" bundle exec rake assets:precompile --quiet

# create tmp/pids
RUN mkdir -p tmp/pids

# db setup
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3000

CMD ["bundle", "exec", "puma"]

