FROM debian:trixie-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends ruby ruby-ffi libvips42t64 fonts-jetbrains-mono \
  && rm -rf /var/lib/apt/lists/* \
  && gem install --no-document ruby-vips -v 2.3.0
