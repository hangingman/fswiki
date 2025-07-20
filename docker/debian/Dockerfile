FROM debian:bookworm-slim

# 環境変数の設定
ENV TZ Asia/Tokyo
ENV ROOT_PASSWORD root
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

# ベースパッケージとビルドツールのインストール
RUN apt-get update -y && \
    apt-get install -y \
    tzdata \
    init \
    bash-completion \
    python3 \
    locales-all \
    curl \
    perl \
    liblocal-lib-perl \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libdb-dev \
    libgdbm-dev \
    libgdbm-compat-dev \
    libreadline-dev \
    uuid-dev && \
    apt-get clean

# SSHのセットアップ
RUN mkdir -p /var/run/sshd && \
    apt-get install -y openssh-server && \
    sed -i 's/^#\(PermitRootLogin\).*/\1 yes/' /etc/ssh/sshd_config && \
    sed -i 's/^\(UsePAM yes\)/# \1/' /etc/ssh/sshd_config && \
    apt clean

# PerlbrewとCartonのインストール
# perlbrewのインストール、Perl 5.30.2のビルド、cpanmのインストールをまとめて実行
RUN curl -L http://install.perlbrew.pl | bash && \
    echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~/.bashrc && \
    /bin/bash -c "source ~/.bashrc && \
    perlbrew init && \
    perlbrew --notest install 5.30.2 && \
    perlbrew switch 5.30.2 && \
    # cpanm自体をインストール
    curl -L https://cpanmin.us | perl - App::cpanminus && \
    # cpanmを使ってCartonをインストール
    cpanm Carton"

# 作業ディレクトリの設定とcpanfileのコピー
WORKDIR /app
COPY cpanfile ./


# carton install をビルド時に実行
RUN /bin/bash -c "source ~/perl5/perlbrew/etc/bashrc && carton install"

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime'; \
    echo 'echo "root:${ROOT_PASSWORD}" | chpasswd'; \
    echo 'exec "$@"' ; \
    } > /usr/local/bin/entry_point.sh; \
    chmod +x /usr/local/bin/entry_point.sh;

EXPOSE 22

ENTRYPOINT ["entry_point.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
