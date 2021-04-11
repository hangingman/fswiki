FROM takeyamajp/debian-sshd

# Debian9の最低限のモジュール、残りはansibleでインストールする
RUN apt-get update -y
RUN apt-get install -y init bash-completion python3 locales-all
RUN apt-get clean all

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

EXPOSE 22

# https://github.com/Praqma/alpine-sshd/blob/master/Dockerfile
# -D in CMD below prevents sshd from becoming a daemon. -e is to log everything to stderr.
CMD ["/usr/sbin/sshd", "-D", "-e"]

