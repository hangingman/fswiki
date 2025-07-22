FROM perl:5.38

# 環境変数の設定
ENV TZ=Asia/Tokyo
ENV LANG=ja_JP.UTF-8
ENV PERL5LIB=/app/local/lib/perl5:/app/local/lib/perl5/x86_64-linux-gnu:/app/local/lib/perl5/x86_64-linux-gnu-thread-multi
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
    locales \
    build-essential && \
    /usr/sbin/locale-gen ja_JP.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# logディレクトリと必要なログファイルを作成
RUN bash -c "mkdir -p log && touch log/{access.log,attach.log,freeze.log,download_count.log}"

# 1. 依存関係定義ファイルのみを先にコピー
RUN cpanm Carton::Snapshot --notest --quiet
RUN cpanm App::cpm --notest --quiet

COPY ./cpanfile /app
COPY ./cpanfile.snapshot /app

# 2. 依存関係をインストール
RUN cpm --version
RUN cpm install --without-develop --without-test

# 3. アプリケーションのソースコードをコピー
COPY . /app

# 4. アプリケーションを実行
CMD ["./env-exec", "/app/local/bin/starman", "--listen", ":8080", "app.psgi"]
