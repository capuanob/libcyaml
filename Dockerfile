# Build Stage
ARG BUILD_VERSION="release"

FROM --platform=linux/amd64 ubuntu:20.04 as base

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake clang git build-essential libyaml-dev

FROM base AS src-debug
WORKDIR /
ADD . /libcyaml
WORKDIR /libcyaml

FROM base AS src-release

## Add source code to the build stage.
WORKDIR /
RUN git clone https://github.com/capuanob/libcyaml.git
WORKDIR /libcyaml
RUN git checkout mayhem

FROM src-${BUILD_VERSION} AS builder

## Build
RUN CC=clang make VARIANT=fuzz
RUN CC=clang make fuzzer VARIANT=fuzz

## Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
COPY --from=builder /libcyaml/build/fuzz/libcyaml-fuzzer /
COPY --from=builder /libcyaml/fuzz/corpus /corpus
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libyaml-dev

## Set up fuzzing!
ENTRYPOINT []
CMD /libcyaml-fuzzer /corpus -close_fd_mask=2
