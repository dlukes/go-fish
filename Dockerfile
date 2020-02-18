FROM ubuntu:18.04

RUN apt-get update && apt-get install -y --no-install-recommends \
  bash \
  build-essential \
  ca-certificates \
  curl \
  git \
  man \
  manpages \
  software-properties-common \
  sudo \
  unzip

COPY gofi.sh /
RUN /gofi.sh

ENTRYPOINT ["fish"]
