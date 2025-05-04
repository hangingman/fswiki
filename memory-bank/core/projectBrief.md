# **Project Brief**

## **プロジェクト名**

FreestyleWiki Cloudflare Workers Migration

## **コア要件と目標**

* Perl製FreestyleWikiの主要機能をCloudflare Workers上で動作するように移植する。  
* 高速でスケーラブル、かつ運用コストの低いサーバーレスWikiを実現する。  
* Cloudflare Workers, D1, KV, R2を活用する。  
* 移植プロセスにおいて、PerlコードのJavaScript/TypeScriptへの変換にClineを利用する。

## **プロジェクト範囲**

* **フェーズ1 (MVP):**  
  * Wikiページの表示 (最新リビジョン)  
  * Wikiページの編集と保存 (履歴管理を含む)  
  * Cloudflare D1, KV, R2へのデータ永続化  
* **フェーズ2以降 (拡張):**  
  * 添付ファイル対応 (R2連携)  
  * 全文検索機能  
  * ユーザー認証・認可  
  * FreestyleWiki固有機能 (マクロ、プラグイン等) の対応または代替実装

## **主要機能**

* ページ表示 (GET /wiki/:title)  
* 編集フォーム表示 (GET /wiki/:title/edit)  
* ページ保存 (POST /wiki/:title/save)  
* リビジョン履歴表示  
* データストア連携 (D1, KV, R2)

## **目標**

* Cloudflare Workersの制限内で効率的に動作する。  
* FreestyleWikiのユーザー体験を可能な限り維持する。  
* 保守性の高いJavaScript/TypeScriptコードベースを構築する。

## **関連リポジトリ**

* (元のFreestyleWikiリポジトリへのリンク \- 該当する場合)  
* (移植版Workersコードのリポジトリへのリンク \- 該当する場合)