FROM perl:5.38

# 環境変数の設定
ENV TZ Asia/Tokyo
ENV LANG ja_JP.UTF-8
ENV PERL5LIB /app/local/lib/perl5
ENV PATH /app/local/bin:$PATH

# ベースパッケージとビルドツールのインストール
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
    tzdata \
    curl \
    libmariadb-dev \
    libjpeg-dev libpng-dev libtiff-dev libgif-dev \
    locales \
    build-essential \
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
RUN carton install --deployment

# 3. アプリケーションのソースコードをコピー
COPY . /app/

# 4. アプリケーションを実行
CMD ["carton", "exec", "starman", "--listen", ":8080", "app.psgi"]