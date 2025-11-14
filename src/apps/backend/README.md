# Backend App

Azure Functions (Node.js 20/22 + TypeScript) プロジェクト。Static Web Apps の `api_location` に `src/apps/backend` を指定すると、フロントエンドと同じリポジトリから Functions をデプロイできます。

## 構成

- `src/functions/ping.ts` … Hono (Fetch API) ベースのHTTPトリガー。`GET /api/ping?name=foo` で疎通確認。
- `tsconfig.json` … `src` → `dist` へトランスパイル（DOM libを有効化し、Honoのfetch型を使用）。
- `host.json` / `.funcignore` / `local.settings.json` … Functions ホスト設定とローカル実行用設定。

## スクリプト

- `npm run dev --workspace @iijan-map/backend` … `func start` を実行（Azure Functions Core Tools v4 が必要）。
- `npm run build --workspace @iijan-map/backend` … TypeScript を `dist` へコンパイル。
- `npm run lint --workspace @iijan-map/backend` … ESLint + Prettierルールでコードスタイル/品質チェック。
- `npm run typecheck --workspace @iijan-map/backend` … `tsc --noEmit` で型チェック。

`src/infra/environments/*.bicepparam` の `apiLocation` を `src/apps/backend` に変更すると、Bicep経由で Static Web Apps と連携できます。
