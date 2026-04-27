ARG DOCKER_VER=29
FROM docker:${DOCKER_VER}

COPY docker-stack-wait.sh /

ENTRYPOINT [ "/docker-stack-wait.sh" ]
