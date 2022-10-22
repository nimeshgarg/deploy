FROM ubuntu:latest

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y curl git python3 unzip
RUN apt-get clean

RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Path: Dockerfile
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter doctor -v
RUN flutter upgrade
COPY ./flutter /app/
WORKDIR /app
RUN flutter build web
