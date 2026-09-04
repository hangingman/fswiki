# プロジェクト概要

## 目的

FSWikiの機能をRakuで再構成し、既存のWikiデータとプラグイン拡張モデルを活用できる移行先を作る。Perl版は動作仕様とCore APIのリファレンスとして扱う。Perlコードの逐語変換は行わない。

## 移行方針

- FSWiki Coreのフック、ハンドラ、プラグイン登録、Storage委譲をRakuで再構成する。
- 既存のプレーンHTTP/HTMLレスポンスを維持する。
- 同じCore/Plugin処理から、HTMLレスポンスとJSON APIレスポンスを生成できるようにする。
- React、VueなどのクライアントはJSON APIを利用する。HTML画面は段階的に置換する。
- 既存の`data/*.wiki`を初期ストレージとして利用する。
- デプロイ先は低コスト環境を優先し、実行要件確定後に選定する。Fly.ioは候補であり決定事項ではない。

## 現在のRaku実装

- `FSWiki::Core`: フック、プラグインメタデータ、アクションハンドラ、Storage委譲。
- `FSWiki::Storage::Memory`: テスト用Storage。
- `FSWiki::Storage::File`: 既存`.wiki`ファイルの読み書き。
- `FSWiki::HTTP::App`: `/health`、`/source/<page>`、`POST /page/<page>`。
- Croの`.cro.yml`による開発時ホットリロード。

## 非目標

- Perl実装のクラス構造・命名・動的ロード機構の再現。
- JSON APIをCore内部メソッド全体から無制限に自動公開すること。
- 初期段階での完全なWikiパーサー、認証、履歴、DB移行。
