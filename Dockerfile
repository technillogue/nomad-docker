# FROM docker/buildx-bin:v0.8 as buildx

# FROM docker:20

# RUN apk add bash ip6tables pigz sysstat procps lsof kakoune curl unzip

FROM flyio/rchab:sha-272d6db
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community/ nomad consul syslog-ng 
# ARG TARGETPLATFORM=linux/amd64
# ARG NOMAD_VERSION=1.4.3
# RUN curl -sOL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_$(echo ${TARGETPLATFORM} | sed 's|/|_|g' | awk -F'_' '{print $1"_"$2}').zip \
#     && unzip nomad_${NOMAD_VERSION}_$(echo ${TARGETPLATFORM} | sed 's|/|_|g' | awk -F'_' '{print $1"_"$2}').zip \
#     && chmod +x ./nomad \
#     && mv nomad /usr/bin/nomad \
#     && rm nomad_${NOMAD_VERSION}_$(echo ${TARGETPLATFORM} | sed 's|/|_|g' | awk -F'_' '{print $1"_"$2}').zip 


#COPY --from=buildx /buildx /root/.docker/cli-plugins/docker-buildx

ENV DOCKER_TMPDIR=/data/docker/tmp
RUN mkdir /data
RUN adduser --disabled-password -Su 1000 -s /bin/bash nomad

#COPY etc/docker/daemon.json /etc/docker/daemon.json

COPY ./entrypoint ./entrypoint
COPY ./docker-entrypoint.d/* ./docker-entrypoint.d/

#USER nomad
COPY ./server.hcl /etc/nomad.d/server.hcl
COPY ./app.nomad ./EK.nomad ./filebeat.nomad /
EXPOSE 8080 4646 4647 4648 4648/udp
ENTRYPOINT ["./entrypoint"]

#CMD ["dockerd", "-p", "/var/run/docker.pid"]
