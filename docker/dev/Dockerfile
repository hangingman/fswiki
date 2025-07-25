FROM perl:5.38

ENV DEBIAN_FRONTEND=noninteractive

# 環境変数の設定
ENV TZ=Asia/Tokyo
ENV LANG=ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8
ENV PERL_BADLANG=0

# ロケール関連のパッケージインストールと設定を早期に行う
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    locales && \
    /usr/sbin/locale-gen ja_JP.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PERL5LIB=/app/local/lib/perl5:/app/local/lib/perl5/x86_64-linux-gnu
ENV PATH=/usr/local/bin:/app/local/bin:$PATH

# ベースパッケージのインストール
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    tzdata \
    curl \
    lsb-release \
    wget \
    gnupg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# MySQL APTリポジトリのGPGキーをインポートし、リポジトリを追加
RUN mkdir -p /usr/share/keyrings && \
    curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | gpg --dearmor -o /usr/share/keyrings/mysql-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/mysql-archive-keyring.gpg] http://repo.mysql.com/apt/debian/ bookworm mysql-8.0" > /etc/apt/sources.list.d/mysql.list && \
    apt-get update && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 開発ツールとライブラリのインストール
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    libmysqlclient-dev \
    libjpeg-dev libpng-dev libtiff-dev libgif-dev \
    libtool autoconf automake \
    build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ./cpanfile /app
RUN cpanm --local-lib=/app/local Carton --notest --quiet

# 下記コマンドでcpanfile.snapshotを生成
# `docker compose -f docker-compose.dev.yml exec dev carton install`

