FROM ubuntu:20.04 as build
ARG COCKROACH_VERSION
RUN apt-get update
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y upgrade
RUN apt-get -y install gcc golang cmake autoconf wget bison libncurses-dev
RUN wget -qO- https://binaries.cockroachdb.com/cockroach-v${COCKROACH_VERSION}.src.tgz | tar xvz
WORKDIR /cockroach-v${COCKROACH_VERSION}
RUN make build
RUN make install

FROM ubuntu:20.04

ARG COCKROACH_VERSION

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y libc6 ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /cockroach && \
    mkdir /usr/local/lib/cockroach && \
    adduser --disabled-password cockroach && \
    adduser cockroach cockroach

WORKDIR /cockroach
ENV PATH=/cockroach:$PATH

COPY --chown=cockroach:cockroach --from=build /usr/local/bin/cockroach /cockroach
COPY --chown=cockroach:cockroach --from=build /cockroach-v${COCKROACH_VERSION}/src/github.com/cockroachdb/cockroach/lib/libgeos.so /cockroach-v${COCKROACH_VERSION}/src/github.com/cockroachdb/cockroach/lib/libgeos_c.so /usr/local/lib/cockroach/ 

RUN chown -R cockroach:cockroach /cockroach

USER cockroach

EXPOSE 26257 8080
ENTRYPOINT ["/cockroach/cockroach"]
