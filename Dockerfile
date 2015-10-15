FROM ruby_baseimage:2.2.3-3

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

ENV http_proxy http://192.168.0.13:3128
ENV https_proxy http://192.168.0.13:3128
ENV SECRET_KEY_BASE 50faff1069e68e8250df63f475c4a0248b65513ced982baacc171bfc81522152f7bbe50ff1572c82b712ea196208b9cacc4c290e92c372b3b372bbe6e576bd3d

# os dependencies
RUN set -x \
    && apt-get update  \
    && apt-get install -y \
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

ENV http_proxy ""
ENV https_proxy ""

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
