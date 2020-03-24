# ------------------------------------------------------------------------------
# dependency stage
# ------------------------------------------------------------------------------
FROM mkenney/npm:latest AS dependencies
ENV INSTALL_PATH /deps
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY package.json ./package.json
COPY package-lock.json ./package-lock.json
RUN npm set progress=false && npm config set depth 0
RUN npm install --save govuk-frontend

# ------------------------------------------------------------------------------
# release stage
# ------------------------------------------------------------------------------

FROM ruby:2.6.3 as release
MAINTAINER dxw <rails@dxw.com>
RUN apt-get update && apt-get install -qq -y \
  build-essential \
  libpq-dev \
  --fix-missing --no-install-recommends
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
        && apt-get install -y nodejs

ENV INSTALL_PATH /srv/beis-roda
RUN mkdir -p $INSTALL_PATH

# This must be ordered before rake assets:precompile
COPY --from=dependencies ./deps/node_modules $INSTALL_PATH/node_modules
COPY --from=dependencies ./deps/node_modules/govuk-frontend/govuk/assets $INSTALL_PATH/app/assets

WORKDIR $INSTALL_PATH

# set rails environment
ARG RAILS_ENV
ENV RAILS_ENV=${RAILS_ENV:-production}
ENV RACK_ENV=${RAILS_ENV:-production}

COPY Gemfile $INSTALL_PATH/Gemfile
COPY Gemfile.lock $INSTALL_PATH/Gemfile.lock

RUN gem update --system 3.0.3
RUN gem update rake 13.0.1
RUN gem install bundler

# bundle ruby gems based on the current environment, default to production
RUN echo $RAILS_ENV
RUN \
  if [ "$RAILS_ENV" = "production" ]; then \
    bundle install --jobs 4 --without development test --retry 10; \
  else \
    bundle install --jobs 4 --retry 10; \
  fi

COPY . $INSTALL_PATH

RUN RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE="super secret" bundle exec rake assets:precompile --quiet

# create tmp/pids
RUN mkdir -p tmp/pids

# db setup
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3000

CMD ["bundle", "exec", "puma"]

# ------------------------------------------------------------------------------
# test stage
# ------------------------------------------------------------------------------

FROM release as test

RUN apt-get install -yy firefox-esr

ARG gecko_driver_version=0.26.0

RUN wget https://github.com/mozilla/geckodriver/releases/download/v$gecko_driver_version/geckodriver-v$gecko_driver_version-linux64.tar.gz
RUN tar -xvzf  geckodriver-v$gecko_driver_version-linux64.tar.gz
RUN rm geckodriver-v$gecko_driver_version-linux64.tar.gz
RUN chmod +x geckodriver
RUN mv geckodriver* /usr/local/bin

CMD [ "bundle", "exec", "rake, default" ]
