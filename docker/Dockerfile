FROM debian:bullseye-slim

# Debian11の最低限のモジュール、残りはansibleでインストールする

# timezone
RUN apt-get update -y
RUN apt-get install -y tzdata init bash-completion python3 locales-all
RUN apt-get clean

# sshd
RUN mkdir /var/run/sshd; \
    apt-get install -y openssh-server; \
    sed -i 's/^#\(PermitRootLogin\) .*/\1 yes/' /etc/ssh/sshd_config; \
    sed -i 's/^\(UsePAM yes\)/# \1/' /etc/ssh/sshd_config; \
    apt clean;

ENV TZ Asia/Tokyo
ENV ROOT_PASSWORD root
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime'; \
    echo 'echo "root:${ROOT_PASSWORD}" | chpasswd'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entry_point.sh; \
    chmod +x /usr/local/bin/entry_point.sh;

EXPOSE 22

# -D in CMD below prevents sshd from becoming a daemon. -e is to log everything to stderr.
ENTRYPOINT ["entry_point.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]

