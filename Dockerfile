FROM ruby:2.4

# start setting up the app
ENV APP_HOME /myapp
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

RUN set -x \
    && apt-get update  \
    && apt-get install -y \
       libsqlite3-dev \
       default-libmysqlclient-dev \
       libv8-dev \
       default-mysql-client \
       git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy the Gemfile as well as the Gemfile.lock and install
# the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those two files
# are made.
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install -j "$(getconf _NPROCESSORS_ONLN)" --retry 5 --without development test

ADD . $APP_HOME
RUN cd $APP_HOME
RUN rake assets:precompile


# setup runit
RUN cd / \
    && git clone https://github.com/purcell/rails-runit.git \
    && cd rails-runit \
    && ln -s $APP_HOME app \
    && ./add-haproxy 3000 \
    && ./add-thin 3001 \
    && ./add-thin 3002 \
    && ./add-thin 3003 \
    && ./add-thin 3004 \
    && cd /etc/service \
    && ln -s /rails-runit/service/* .



EXPOSE 3000
