# Frontend App

Next.js 15 (App Router) + React 19 + TypeScript を想定したフロントエンド。Azure Static Web Apps へのデプロイを前提に `src/infra` ディレクトリの Bicep テンプレートから `appLocation` = `src/frontend` を参照する。

- `package.json` / `next.config.ts` 等は今後追加。
- ビルド成果物は `.next/` ディレクトリを Static Web Apps が参照できるよう `appArtifactLocation` に設定する。
