# Instagram Graph API client (Axios + TypeScript)

Instagram Graph API を Axios で叩くための TypeScript ユーティリティです。`graph.facebook.com` に対する GET/POST の定形処理（アクセストークン付与、エラーハンドリング）をまとめています。

## 使い方

```ts
import { InstagramGraphClient } from '@iijan-map/instagram-graph-client';

const client = new InstagramGraphClient({
  accessToken: process.env.IG_ACCESS_TOKEN!,
  // apiVersion: 'v19.0', // 省略可
  // timeoutMs: 10_000,   // 省略可
});

const me = await client.getUserProfile('me');
const media = await client.listRecentMedia('me', { limit: 5 });

// 画像投稿（コンテナ作成＋即時公開）
await client.publishImage({
  userId: me.id,
  imageUrl: 'https://example.com/photo.jpg',
  caption: 'New photo from our cafe!',
});

// 短期トークンを長期トークンに交換
const longLived = await InstagramGraphClient.exchangeLongLivedToken({
  appId: process.env.META_APP_ID!,
  appSecret: process.env.META_APP_SECRET!,
  shortLivedToken: process.env.IG_SHORT_LIVED_TOKEN!,
});
```

### 主なメソッド

- `getUserProfile(userId, fields?)`: `/userId` を取得。フィールドは `fields` で上書き可。
- `listRecentMedia(userId, options?)`: `/userId/media` をページング付きで取得。
- `getMedia(mediaId, fields?)`: 単一メディア詳細。
- `publishImage({ userId, imageUrl, caption?, publish? })`: 画像コンテナ作成＆公開（`publish: false` でコンテナ作成のみ）。
- `exchangeLongLivedToken({ appId, appSecret, shortLivedToken, apiVersion?, timeoutMs? })`: 短期トークン → 長期トークン交換。

### リクエスト/エラー処理

- すべてのリクエストは `access_token` をクエリに付与します。
- Graph API のエラーオブジェクトを `InstagramGraphError` に変換し、`status/code/type` を引き回します。
