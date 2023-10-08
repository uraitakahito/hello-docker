# Debian 12.1
FROM debian:bookworm-20230919

# Default UID and GID on MacOS
ARG user_id=501
ARG group_id=20

ARG user_name=developer
# The WORKDIR instruction can resolve environment variables previously set using ENV.
# You can only use environment variables explicitly set in the Dockerfile.
# https://docs.docker.com/engine/reference/builder/#/workdir
ARG home=/home/${user_name}

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    less \
    sudo \
    procps \
    zsh \
    sed \
    curl \
    ca-certificates \
    iputils-ping \
    net-tools \
    git \
    gnupg2
RUN apt-get install -y --no-install-recommends vim emacs
RUN apt-get install -y --no-install-recommends \
  tmux \
  # fzf needs PAGER(less or something)
  fzf \
  exa \
  trash-cli

COPY bin/* /usr/local/bin/
RUN /usr/local/bin/set-superuser-and-group.sh ${group_id} ${user_id} ${user_name}

RUN chown -R ${user_id}:${group_id} ${home}
USER ${user_name}

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["tail", "-F", "/dev/null"]
