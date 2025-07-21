FROM debian:bookworm-slim

# 必要なパッケージをインストール
# libdbd-mysql-perl を入れることで、依存関係が自動で解決されます
RUN apt-get update && \
    apt-get install -y perl libdbd-mysql-perl && \
    rm -rf /var/lib/apt/lists/*

# スクリプトをコンテナにコピー
COPY check_db.pl /app/
WORKDIR /app

# コンテナ起動時に実行するコマンド
CMD ["perl", "check_db.pl"]

