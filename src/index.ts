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

import { WikiApplication } from './services/wikiApplication'; // WikiApplicationをインポート

// 環境変数インターフェース (wrangler.jsoncで定義したBindingに対応)
interface Env {
	DB: D1Database;
	CACHE: KVNamespace;
	BUCKET: R2Bucket; // R2も使用する可能性があるため追加
}

export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		// WikiApplicationのインスタンスを作成し、リクエスト処理を委譲
		const wikiApplication = new WikiApplication(env);
		return wikiApplication.handleRequest(request);
	},
} satisfies ExportedHandler<Env>;
