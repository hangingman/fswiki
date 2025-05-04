/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run `npm run dev` in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run `npm run deploy` to publish your worker
 *
 * Bind resources to your worker in `wrangler.jsonc`. After adding bindings, a type definition for the
 * `Env` object can be regenerated with `npm run cf-typegen`.
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

import { handleWikiPageRequest } from './handlers/wiki'; // 作成したハンドラをインポート

// 環境変数インターフェース (wrangler.jsoncで定義したBindingに対応)
interface Env {
	DB: D1Database;
	CACHE: KVNamespace;
	BUCKET: R2Bucket; // R2も使用する可能性があるため追加
}

export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		const url = new URL(request.url);
		const path = url.pathname;

		// Wikiページ表示ルートのパターンマッチ
		const wikiPageMatch = path.match(/^\/wiki\/(.+)$/);

		if (request.method === 'GET' && wikiPageMatch) {
			// パスパラメータからタイトルを取得し、handleWikiPageRequestに渡す
			const title = wikiPageMatch[1];
			// handleWikiPageRequestを呼び出す (Requestオブジェクトとタイトルを渡す)
			return handleWikiPageRequest(request, title, env, ctx);
		}

		// TODO: その他のルートを追加 (編集、保存、履歴など)
		// if (request.method === 'GET' && path.match(/^\/wiki\/(.+)\/edit$/)) {
		//   // handleEditPageRequestを呼び出す
		// }
		// if (request.method === 'POST' && path.match(/^\/wiki\/(.+)\/save$/)) {
		//   // handleSavePageRequestを呼び出す
		// }


		// デフォルトルート (既存の例を残しておくか、削除するかは検討)
		switch (path) {
			case '/message':
				return new Response('Hello, World!');
			case '/random':
				return new Response(crypto.randomUUID());
			default:
				// ルートが見つからない場合のハンドラ
				return new Response('Not Found', { status: 404 });
		}
	},
} satisfies ExportedHandler<Env>;
