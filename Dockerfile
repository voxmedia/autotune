FROM ruby:2.2.4

RUN apt-get update \
	&& apt-get upgrade -y

RUN gem install bundler \
	&& mkdir /app \
	&& mkdir /app/tmp \
	&& mkdir /root/.ssh \
	&& echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

WORKDIR /app

ADD ["Gemfile", "autotune.gemspec", "/app/"]

ENV RAILS_ENV test

# Doing bundle install here (after the app is mounted a volune)
# rather than in the docker_tests.sh script because bundle won't
# run with '--deployment' because there is no Gemfile.lock,
# and if run as 'docker run' command, it seems to not actualy install the git based gems
CMD bin/docker_cmd.sh
