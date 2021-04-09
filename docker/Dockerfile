FROM debian:stretch-20210329
USER root

# Debian9の最低限のモジュール、残りはansibleでインストールする
RUN apt-get update -y
RUN apt-get install -y lsb-release lsb-core init bash-completion
RUN apt-get clean all
RUN /usr/bin/lsb_release -a

EXPOSE 22
CMD ["/sbin/init"]
