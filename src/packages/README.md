# Shared Packages

フロントエンド/バックエンド共通のユーティリティやUI部品は `src/packages` 配下で管理する。npmワークスペースとして `package.json` に登録されるため、`npm install` 後に `src/packages/*` 内の依存も同時管理される。

例:

```
src/packages/shared-utils
src/packages/ui-components
src/packages/instagram-graph-client
```

必要に応じて `npm init -w src/packages/<name>` でパッケージを追加する。
