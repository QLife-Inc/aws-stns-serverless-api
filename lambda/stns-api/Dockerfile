FROM ruby:2.5.0

RUN mkdir /app
WORKDIR /app
COPY src/Gemfile* /app/
RUN bundle install --without test
