import { IRequest, IttyRouter } from 'itty-router';
import { D1Database, KVNamespace } from '@cloudflare/workers-types';
import { WikiApplication } from '../services/wikiApplication';

// 環境変数インターフェース
interface Env {
	DB: D1Database;
	CACHE: KVNamespace;
	BUCKET: R2Bucket; // R2バインディングを追加
}

// Wikiページ表示ハンドラ
// Requestオブジェクトとタイトルを引数に取るように変更
export async function handleWikiPageRequest(request: Request, title: string, env: Env, ctx: ExecutionContext): Promise<Response> {

	if (!title) {
		// タイトルがない場合のエラーハンドリング (src/index.tsでチェックされるはずだが念のため)
	return new Response('Page title is missing', { status: 400 });
}

// KVキャッシュからの読み取りロジック
const cachedPage = await env.CACHE.get(`page:${title}`);
if (cachedPage) {
  // キャッシュがあればそれを返す
  return new Response(cachedPage, { headers: { 'Content-Type': 'text/html' } });
}

// D1からのページデータ取得ロジック
// D1Resultの型を適切に定義する必要があるが、ここではanyを使用
const pageData = await env.DB.prepare('SELECT * FROM pages WHERE title = ?').bind(title).first<{ content: string }>();

if (!pageData) {
  // ページが存在しない場合
  return new Response(`Page "${title}" not found`, { status: 404 });
}

// TODO: 取得したページデータをHTMLにレンダリングするロジックを実装
// const htmlContent = renderPageToHtml(pageData.content); // renderPageToHtmlは別途実装

// TODO: KVキャッシュに保存するロジックを実装 (任意)
// await env.CACHE.put(`page:${title}`, htmlContent, { expirationTtl: 3600 }); // 例: 1時間キャッシュ

// WikiApplicationスタブを使用してHTMLにレンダリング
const wikiApplication = new WikiApplication(env);
const htmlContent = await wikiApplication.renderWikiText(pageData.content);

// HTMLコンテンツを返す
return new Response(htmlContent, { headers: { 'Content-Type': 'text/html' } });
}

// TODO: 編集フォーム表示ハンドラ (後で実装)
// export async function handleEditPageRequest(request: IRequest, env: Env, ctx: ExecutionContext): Promise<Response> {
//   const title = request.params?.title;
//   // ... 編集フォーム表示ロジック ...
//   return new Response(`Edit page: ${title}`);
// }

// TODO: ページ保存ハンドラ (後で実装)
// export async function handleSavePageRequest(request: IRequest, env: Env, ctx: ExecutionContext): Promise<Response> {
//   const title = request.params?.title;
//   // ... ページ保存ロジック ...
//   return new Response(`Save page: ${title}`);
// }

// TODO: その他のハンドラ (履歴表示など)
