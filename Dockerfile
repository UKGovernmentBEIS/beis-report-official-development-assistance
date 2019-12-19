# Install dependencies into a seperate and isolated Docker stage
# that is thrown away apart from any subsequent COPY commands
FROM mkenney/npm:latest AS dependencies
ENV INSTALL_PATH /deps
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY package.json ./package.json
COPY package-lock.json ./package-lock.json
RUN npm set progress=false && npm config set depth 0
RUN npm install --save govuk-frontend

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

# db setup
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3000

CMD ["bundle", "exec", "puma"]
