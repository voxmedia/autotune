FROM ruby:2.2.4

RUN apt-get update \
	&& apt-get upgrade -y

RUN gem install bundler \
	&& mkdir /app \
	&& mkdir /app/tmp \
	&& mkdir /root/.ssh \
	&& echo "Host github.com\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

WORKDIR /app
