FROM perl:5.38

# 環境変数の設定
ENV TZ Asia/Tokyo
ENV LANG ja_JP.UTF-8
ENV PERL5LIB /app/local/lib/perl5:/app/local/lib/perl5/x86_64-linux-gnu-thread-multi
ENV PATH /app/local/bin:$PATH

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
    build-essential \
    cpanminus \
    carton && \
    /usr/sbin/locale-gen ja_JP.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# logディレクトリと必要なログファイルを作成
RUN bash -c "mkdir -p log && touch log/{access.log,attach.log,freeze.log,download_count.log}"

# 1. 依存関係定義ファイルのみを先にコピー
COPY cpanfile /app/
# リポジトリにあるsnapshotをコピー
COPY ./cpanfile.snapshot /app/

# 2. 依存関係をインストール
# この時点で local/bin/plackup などが「コンテナ内の正しいshebang」で生成される
# Devel::CheckLibはテストが失敗するため、--forceで強制インストール
RUN cpanm --force Devel::CheckLib
# DBD::mysqlをインストール
RUN cpanm DBD::mysql
RUN carton install --deployment

# 3. アプリケーションのソースコードをコピー
COPY . /app/

# 4. アプリケーションを実行
CMD ["carton", "exec", "starman", "--listen", ":8080", "app.psgi"]
