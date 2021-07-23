FROM alpine:latest
#FROM anapsix/alpine-java:8_jdk_nashorn

# Define environment variables.
ENV BUILD_DATE=06292021
ENV MULE_HOME=/app/mule
ENV MULE_VERSION=4.3.0-20210119
ENV MULE_MD5=0859dad4a6dd992361d34837658e517d
ENV TINI_SUBREAPER=
ENV TZ=UTC

# SSL Cert for downloading mule zip
RUN apk --no-cache update && \
    apk --no-cache upgrade && \
    apk --no-cache add ca-certificates && \
	apk --no-cache add openjdk8 && \
    update-ca-certificates && \
    apk --no-cache add openssl && \
    apk add --update tzdata && \
    rm -rf /var/cache/apk/*

RUN	wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
	wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-2.32-r0.apk && \
	apk add glibc-2.32-r0.apk curl

RUN adduser -D -g "" 185 root -u 185


RUN mkdir /app
#RUN chgrp -R 185 /app/ && \
#RUN chmod -R 777 /app/ && \
#RUN id -nu 185 | xargs -I{} chown -R {}:{} /app/

RUN echo ${TZ} > /etc/timezone

#USER 185
RUN mkdir /app/mule-standalone-${MULE_VERSION} && \
    ln -s /app/mule-standalone-${MULE_VERSION} ${MULE_HOME}
	
# For checksum, alpine linux needs two spaces between checksum and file name
RUN cd ~ && wget https://repository-master.mulesoft.org/nexus/content/repositories/releases/org/mule/distributions/mule-standalone/${MULE_VERSION}/mule-standalone-${MULE_VERSION}.tar.gz && \
    echo "${MULE_MD5}  mule-standalone-${MULE_VERSION}.tar.gz" | md5sum -c && \
    cd /app && \ 
    tar xvzf ~/mule-standalone-${MULE_VERSION}.tar.gz && \
    rm ~/mule-standalone-${MULE_VERSION}.tar.gz

# Define mount points.
COPY wrapper.conf /app/mule-standalone-${MULE_VERSION}/conf/wrapper.conf
COPY helloworld.jar /app/mule-standalone-${MULE_VERSION}/apps/hello-world.jar

#USER root
#RUN id -u 185 | xargs -I{} chown {}:{} /app/mule-standalone-${MULE_VERSION}/conf/wrapper.conf
#RUN id -u 185 | xargs -I{} chown {}:{} /app/mule-standalone-${MULE_VERSION}/apps/hello-world.jar
#RUN chmod -R 777 /app/

RUN chgrp -R 0 /app/mule && \
    chmod -R g+rwX /app/mule

USER 185
VOLUME ["${MULE_HOME}/logs", "${MULE_HOME}/conf", "${MULE_HOME}/apps", "${MULE_HOME}/domains"]

# Define working directory.
WORKDIR ${MULE_HOME}



# Default http port
EXPOSE 8081

ENTRYPOINT [ "/app/mule/bin/mule"]


