FROM ruby_baseimage:2.2.3

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# os dependencies
RUN apt-get update -qq \
    && apt-get install -y haproxy \
       haproxy \
       libsqlite3-dev \
       libmysqlclient-dev \
       libv8-dev \
       mysql-client \
       git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# start setting up the app
ENV APP_HOME /myapp
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/
RUN bundle install
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
