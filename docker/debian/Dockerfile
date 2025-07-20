FROM perl:5.38.2-slim-threaded-bookworm

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

# 作業ディレクトリの設定とcpanfileのコピー
WORKDIR /app
COPY . /app/

# Perlモジュールのインストール
RUN carton install --deployment

# ポートの公開
EXPOSE 5000

# アプリケーションの起動
CMD ["starman", "--listen", "0.0.0.0:5000", "app.psgi"]
