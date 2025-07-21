FROM perl:5.38

# 環境変数の設定
ENV TZ Asia/Tokyo
ENV LANG ja_JP.UTF-8

# ベースパッケージとビルドツールのインストール
RUN apt-get update -y && \
    apt-get install -y \
    tzdata \
    curl \
    libmariadb-dev \
    libjpeg-dev libpng-dev libtiff-dev libgif-dev \
    locales \
    build-essential \
    carton && \
    /usr/sbin/locale-gen ja_JP.UTF-8 && \
    apt-get clean

WORKDIR /app

# 1. 依存関係定義ファイルのみを先にコピー
COPY cpanfile /app/
# リポジトリにあるsnapshotをコピー
COPY ./cpanfile.snapshot /app/



# 3. 依存関係をインストール
# この時点で local/bin/plackup などが「コンテナ内の正しいshebang」で生成される
RUN carton install --deployment

# 4. アプリケーションのソースコードをコピー
COPY . /app/

# 5. アプリケーションを実行
CMD ["carton", "exec", "plackup", "-p", "8080", "app.psgi"]