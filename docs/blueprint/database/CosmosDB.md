# Cosmos DB データ定義書

## 1. 想定ワークロード

- データベース: Azure Cosmos DB for NoSQL (Serverless)。1リージョン、分析ストア無効。
- クライアント: Azure Functions (HTTP/Timer/Change Feed) が `stores` へ週次 upsert（最大150件/バッチ）、`userFavorites` へリアルタイム書き込み（1桁件数/日）。フロントエンドは `/stores`, `/stores/{id}`, `/favorites` API を通じてポイントリード中心の参照を行う。
- キャッシュ: `geoTiles` と `placeCache` は TTL 制御で短期キャッシュを保持し、CDN/IndexedDB キャッシュとの二重構成で RU を節約する（`docs/architecture/CacheStrategy.md`）。
- Change Feed: `stores` → Azure Cognitive Search 更新、`userFavorites` → 将来の差分通知。`geoTiles`, `placeCache`, `syncState` では無効。

## 2. コンテナ一覧

| Container | Partition Key | TTL | Unique Key | Change Feed | 用途 |
| --- | --- | --- | --- | --- | --- |
| `stores` | `/storeId` | 無効 (`-1`) | なし | `AllVersionsAndDeletes` | 店舗マスタ・AI要約・Places値。 |
| `userFavorites` | `/userId` | 無効 | `[{paths:["/userId","/storeId"]}]` | `LatestVersion` | ユーザー別お気に入り履歴。 |
| `geoTiles` | `/boundsHash` | 300 秒 | なし | 無効 | `GET /stores?bounds` のGeoJSONキャッシュ。 |
| `placeCache` | `/placeId` | 86,400 秒 | なし | 無効 | Google Places詳細キャッシュ。 |
| `syncState` | `/scope` | 2,592,000 秒 (30日) | なし | 無効 | ETL実行状態・カーソル管理。 |

> Serverless RU 消費見積: `stores` 書き込み 6～10 RU/件、ポイントリード 1～2 RU/件。`geoTiles` 読み込みは TTL と CDN キャッシュで80%以上ヒットさせ、Cosmos 読み込みを 50 RU/日 以下に抑える。

## 3. コンテナ詳細

### 3.1 `stores`

**Partition / RU**
- `storeId` はすべての API でキー入力されるためパーティションキーに採用し、ポイントリードのみで `/stores/{id}` を処理する。1店舗 ≒ 1KB～3KB で RU を最小化。
- Change Feed を `AllVersionsAndDeletes` に設定し、GeoJSON キャッシュや Search インデックスと完全同期させる。

**データスキーマ**

| フィールド | 型 | 説明 |
| --- | --- | --- |
| `id`, `storeId` | string | `store_{slug}`。`id` と `storeId` は同一値。 |
| `name`, `category` | string | 店舗の表示名とカテゴリ（`cafe`, `restaurant`, `bar` 等）。 |
| `address.full` | string | 郵便番号含む住所。 |
| `address.city` / `postalCode` | string | UI フィルタ用の都市/郵便番号。 |
| `coords` | GeoJSON Point | `[lng, lat]`。フォールバック Geo クエリ用。 |
| `regionKey` | string | `tokyo-23ku` などの業務キー。 |
| `gridKey` | string | GeoHash(4) など。Geo 分割キャッシュで利用。 |
| `priceRange` | string | `￥`, `￥￥`, `￥￥￥`。 |
| `capacity` | object | `seats`(number), `wifi`(bool), `power`(`none/few/many`)。 |
| `ai.summary` | string | gpt-4o-mini が生成した説明（最大500文字）。 |
| `ai.tags` | string[] | 雰囲気/用途タグ。 |
| `ai.trendScore` | number | 0〜1 スコア。 |
| `ai.crowdLevel` | string | `low/moderate/high`。 |
| `ai.updatedAt` | string (ISO8601) | AI更新時刻。 |
| `popularity.score` | number | SNS/口コミから計算した人気度。 |
| `popularity.sources.instagram/google` | number | 情報源ごとの貢献度。 |
| `places.placeId` | string | Google Places ID。 |
| `places.rating` | number | 1〜5。 |
| `places.reviewCount` | number | Placesでのレビュー件数。 |
| `places.lastFetched` | string | Places を最後に取得した日時。 |
| `favorites.count` | number | お気に入り数。 |
| `favorites.updatedAt` | string | お気に入り数更新日時。 |
| `media.heroPhoto` | string | 主画像 URL。 |
| `media.instagram` | string[] | 代表 Instagram リンク。 |
| `media.photoAttribution` | string[] | クレジット。 |
| `etl.sources` | string[] | `["instagram","googlePlaces"]` など。 |
| `etl.lastUpsert` | string | 最終 upsert。 |
| `etl.etag` | string | Cosmos ETag をコピーしてクライアント連携。 |

**JSON 例**

```json
{
  "id": "store_tokyo_lattelab",
  "storeId": "store_tokyo_lattelab",
  "name": "Latte Lab",
  "category": "cafe",
  "address": {
    "full": "東京都港区六本木1-1-1",
    "city": "Minato",
    "postalCode": "106-0032"
  },
  "coords": {"type": "Point", "coordinates": [139.7301, 35.6522]},
  "regionKey": "tokyo-23ku",
  "gridKey": "9q60",
  "priceRange": "￥￥",
  "capacity": {"seats": 45, "wifi": true, "power": "many"},
  "ai": {
    "summary": "落ち着いた雰囲気でPC作業向け。",
    "tags": ["落ち着いた", "作業向け", "写真映え"],
    "trendScore": 0.72,
    "crowdLevel": "moderate",
    "updatedAt": "2024-05-18T12:00:00Z"
  },
  "popularity": {"score": 86, "sources": {"instagram": 52, "google": 34}},
  "places": {"placeId": "ChIJ...", "rating": 4.5, "reviewCount": 210, "lastFetched": "2024-05-17T07:30:00Z"},
  "favorites": {"count": 8, "updatedAt": "2024-05-18T13:00:00Z"},
  "media": {"heroPhoto": "https://...", "instagram": ["https://..."], "photoAttribution": ["@userA"]},
  "etl": {"sources": ["instagram", "googlePlaces"], "lastUpsert": "2024-05-18T12:05:00Z", "etag": "\"a1b2c3\""}
}
```

**インデックス定義**

```json
{
  "automatic": true,
  "indexingMode": "consistent",
  "includedPaths": [
    {"path": "/storeId/?"},
    {"path": "/name/?"},
    {"path": "/category/?"},
    {"path": "/regionKey/?"},
    {"path": "/gridKey/?"},
    {"path": "/ai/tags/?"},
    {"path": "/popularity/score/?", "indexes": [{"kind": "Range", "dataType": "Number"}]},
    {"path": "/favorites/count/?", "indexes": [{"kind": "Range", "dataType": "Number"}]},
    {"path": "/places/lastFetched/?", "indexes": [{"kind": "Range", "dataType": "String"}]},
    {"path": "/etl/lastUpsert/?", "indexes": [{"kind": "Range", "dataType": "String"}]}
  ],
  "excludedPaths": [
    {"path": "/media/*"},
    {"path": "/ai/summary/?"},
    {"path": "/reviews/*"}
  ],
  "compositeIndexes": [
    [
      {"path": "/regionKey", "order": "ascending"},
      {"path": "/popularity/score", "order": "descending"}
    ],
    [
      {"path": "/regionKey", "order": "ascending"},
      {"path": "/places/rating", "order": "descending"}
    ],
    [
      {"path": "/gridKey", "order": "ascending"},
      {"path": "/favorites/count", "order": "descending"}
    ]
  ],
  "spatialIndexes": [
    {"path": "/coords/?", "types": ["Point"]}
  ]
}
```

**パフォーマンス**
- `media`, `reviews` を除外し書き込み RU を約30%削減。平均 2KB/ドキュメントの場合、週2回150件 upsert で 3,000 RU/週 程度。
- `/stores` API の fallback クエリは `regionKey` + `gridKey` を WHERE に含め、スキャン RU を 5 RU 未満に抑える。

### 3.2 `userFavorites`

**Partition / RU**
- `userId` ごとに 1 パーティション。招待制で最大6ユーザーのためホットパーティションリスクは無い。
- Unique Key で `userId + storeId` の重複を禁止。1件 ≒ 200B、ポイントリード 1 RU 未満。

**データスキーマ**

| フィールド | 型 | 説明 |
| --- | --- | --- |
| `id` | string | `storeId` と同一値。 |
| `userId` | string | 招待制ユーザー ID。 |
| `storeId` | string | お気に入り店舗 ID。 |
| `action` | string | `add` or `remove`。 |
| `note` | string | 任意メモ（最大200文字）。 |
| `labels` | string[] | `["work","date"]` 等。 |
| `updatedAt` | string | ISO8601。差分ポーリングキー。 |
| `source` | string | `web-app`, `import` など。 |
| `etag` | string | Cosmos ETag を格納し、フロントが `If-Match` で送信。 |

**インデックス定義**

```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {"path": "/userId/?"},
    {"path": "/storeId/?"},
    {"path": "/updatedAt/?"},
    {"path": "/action/?"},
    {"path": "/labels/?"}
  ],
  "compositeIndexes": [
    [
      {"path": "/updatedAt", "order": "descending"},
      {"path": "/storeId", "order": "ascending"}
    ]
  ]
}
```

**パフォーマンス**
- `/favorites` GET は `partitionKey = userId` を指定したポイントクエリ (1〜2 RU)。
- Change Feed (LatestVersion) をキューに流すときも 1イベント ≒ 200B で RU 微小。

### 3.3 `geoTiles`

**Partition / RU**
- `boundsHash` をパーティションキーに固定。`hash(latMin,latMax,lngMin,lngMax,zoom,filters)` を Base16 文字列で保存。
- `defaultTtl = 300` で自動削除。1タイル ≒ 10〜15KB、書き込み 20 RU 程度だが CDN/IndexedDB が 80% ヒットするため Cosmos への書き込み頻度は低い。

**データスキーマ**

| フィールド | 型 | 説明 |
| --- | --- | --- |
| `id` | string | `tile_{hash}`。 |
| `boundsHash` | string | パーティションキー。 |
| `filters` | object | クエリフィルタを正規化した JSON。 |
| `zoom` | number | Google Maps ズームレベル。 |
| `generatedAt` | string | GeoJSON 生成時刻。 |
| `expiresAt` | string | `generatedAt + 5m`（TTL 管理の補助）。 |
| `featureCount` | number | ピン数。 |
| `sourceVersion` | string | 生成時に参照した `stores` の ETag。 |
| `geojson` | object | FeatureCollection (最大20KB)。 |

**インデックス定義**

```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {"path": "/boundsHash/?"},
    {"path": "/filters/*"},
    {"path": "/zoom/?"},
    {"path": "/generatedAt/?"},
    {"path": "/featureCount/?"}
  ],
  "excludedPaths": [
    {"path": "/geojson/*"}
  ]
}
```

**パフォーマンス**
- キャッシュヒット時は Cosmos へのアクセスなし。ミス時のみ 1 ポイントリード + 1 upsert (約30 RU)。
- `featureCount` をインデックス化しておくことで、キャッシュ異常時の監視クエリ（例: 50件超のタイル検出）が低 RU で実行できる。

### 3.4 `placeCache`

**Partition / RU**
- `placeId` をパーティションキー。`defaultTtl = 86400` で 24時間キャッシュし、期限切れ時にのみ Google Places API を呼び出す。
- 1件 ≒ 3KB（レビュー5件上限）。書き込み 10 RU、読み取り 2 RU 程度。

**データスキーマ**

| フィールド | 型 | 説明 |
| --- | --- | --- |
| `id`, `placeId` | string | Google Places ID。 |
| `storeId` | string | `stores` への逆参照。 |
| `lastFetched` | string | API 取得完了時刻。 |
| `status` | string | `fresh`, `stale`, `error`。 |
| `fields.rating`, `fields.priceLevel` | number | Places から取得した値。 |
| `fields.reviews` | array | 最新5件 `{author, rating, text, time}`。 |
| `fields.openingHours` | object | 営業時間。 |
| `etag` | string | キャッシュ整合性用。 |

**インデックス定義**

```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {"path": "/placeId/?"},
    {"path": "/storeId/?"},
    {"path": "/lastFetched/?"},
    {"path": "/status/?"}
  ],
  "excludedPaths": [
    {"path": "/fields/reviews/*"}
  ]
}
```

**パフォーマンス**
- `/stores/{id}` はまず `placeCache` をポイントリード (1 RU) し、`lastFetched` が24時間以内なら Google API をスキップ。
- 異常時は `status="stale"` を書き込み TTL に頼らず再フェッチを強制し、RU 影響は 1件 10 RU 以内。

### 3.5 `syncState`

**Partition / RU**
- `scope`（`instagram`, `places`, `searchIndex`, `favoritesFeed` 等）で一意。1ドキュメントあたり 300B 程度。
- `defaultTtl = 2592000` で 30日保持し、古いジョブログを自動削除。

**データスキーマ**

| フィールド | 型 | 説明 |
| --- | --- | --- |
| `id`, `scope` | string | スコープ名。 |
| `lastRun` | string | 最終実行開始時刻。 |
| `lastSuccess` | string | 直近成功時刻。 |
| `cursor` | string | 差分取得カーソル（日時/ID）。 |
| `failureCount` | number | 連続失敗回数。 |
| `nextRun` | string | 次回実行予定。 |
| `meta.batchSize` | number | 実行バッチサイズ。 |
| `meta.tokenExpiresAt` | string | API トークン期限。 |

**インデックス定義**

デフォルト設定（全フィールド自動インデックス化）で充分。追加オプションは不要。

**パフォーマンス**
- タイマートリガー Functions がポイントリード → upsert を 1実行あたり2回行うのみ。 RU 消費は 5 RU 未満。

## 4. 実装タスク

1. Cosmos DB の IaC (Bicep) に 5 コンテナを定義し、パーティションキー/TTL/UniqueKey/ChangeFeed/IndexingPolicy を本書通りに設定する。
2. `stores` Change Feed を Search 更新 Functions と GeoJSON 再生成 Functions の両方へ接続し、削除イベントも処理する。
3. Functions 実装はすべて `partitionKey` を明示し、ポイントリード API (`readItem`) を優先。クエリ使用時も `regionKey`, `gridKey` でフィルタして RU を抑える。
4. Application Insights に `cache_hit`, `cache_miss`, `cosmos_ru` カスタムメトリクスを送信し、`geoTiles`/`placeCache` のヒット率 80%以上、Cosmos 日次 RU 500 以下を維持する。
