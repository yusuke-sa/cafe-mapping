# Cognitive Search インデックス設計草案

要件: `docs/product/RequirementsDefinition.md` の検索/マップ要件、`docs/blueprint/database/CosmosDB.md` の `stores` コンテナ、`docs/blueprint/dataflow/DataFlow_SearchIndex.md` `DataFlow_MapTiles.md` のフローを前提に、実装時に迷わないレベルで定義する。

## 1. サービス/運用方針

- プラン: 本番は Basic（ベクトル/HNSW利用、容量余裕）。開発は Free でも可だがフィールド/サイズ制約を念頭に同一スキーマを保つ。
- インデックス: `stores-index`（本番）、`stores-index-dev`（開発）。インデックス数は最小限。
- SLA: Change Feed 反映 5分以内を目標。失敗時は指数バックオフ (1s,3s,9s) で3回まで再試行し App Insights へアラート。
- Secrets: 管理キーは Key Vault に保管し Functions から取得。

## 2. フィールド定義（`stores-index`）

共通設定: `defaultAnalyzer=ja.microsoft`。`semanticSearch` 有効 (`contentFields`: `summary`, `tags`, `category`)。`vectorSearch` HNSW cosine (m=40, efConstruction=400, efSearch=80)。`suggester=sg` (`name`, `altNames`, `tags`, `areaLabels`)。

| フィールド | 型 | 属性 | 値/マッピング |
| --- | --- | --- | --- |
| `storeId` | Edm.String | **Key**, filterable, sortable | Cosmos `storeId` (= `id`) |
| `name` | Edm.String | searchable, filterable, sortable | 店名 |
| `altNames` | Collection(Edm.String) | searchable, filterable | 英語名/旧名/略称 |
| `category` | Edm.String | searchable, filterable, facetable | `cafe`/`restaurant`/`bar` |
| `priceRange` | Edm.String | filterable, facetable | `￥`/`￥￥`/`￥￥￥` |
| `address` | Edm.String | searchable | 住所全文 |
| `city` | Edm.String | filterable, facetable | UI フィルタ用 |
| `regionKey` | Edm.String | filterable, facetable, sortable | 例: `tokyo-23ku` |
| `gridKey` | Edm.String | filterable, facetable | Geo 分割キー |
| `location` | Edm.GeographyPoint | filterable, sortable | `[lon,lat]` |
| `tags` | Collection(Edm.String) | searchable, filterable, facetable | Cosmos `ai.tags`（正規化済みlowercase） |
| `summary` | Edm.String | searchable | Cosmos `ai.summary`（最大500文字） |
| `trendScore` | Edm.Double | filterable, sortable | Cosmos `ai.trendScore` |
| `crowdLevel` | Edm.String | filterable, facetable | `low`/`moderate`/`high` |
| `popularityScore` | Edm.Double | filterable, sortable | Cosmos `popularity.score` |
| `rating` | Edm.Double | filterable, sortable | Cosmos `places.rating` |
| `reviewCount` | Edm.Int32 | filterable, sortable | Cosmos `places.reviewCount` |
| `wifi` | Edm.Boolean | filterable, facetable | Cosmos `capacity.wifi` |
| `power` | Edm.String | filterable, facetable | `none`/`few`/`many` |
| `seats` | Edm.Int32 | filterable, sortable | Cosmos `capacity.seats` |
| `priceLevel` | Edm.Int32 | filterable, facetable | Places `fields.priceLevel`（あれば） |
| `favoriteCount` | Edm.Int32 | filterable, sortable | Cosmos `favorites.count` |
| `heroPhoto` | Edm.String | retrievable | 代表画像URL |
| `placeId` | Edm.String | filterable, sortable | Google Places ID |
| `etlSources` | Collection(Edm.String) | filterable, facetable | `["instagram","googlePlaces"]` 等 |
| `lastUpdated` | Edm.DateTimeOffset | filterable, sortable | Cosmos `etl.lastUpsert` |
| `aiUpdatedAt` | Edm.DateTimeOffset | filterable, sortable | Cosmos `ai.updatedAt` |
| `placesLastFetched` | Edm.DateTimeOffset | filterable, sortable | Cosmos `places.lastFetched` |
| `cosmosEtag` | Edm.String | retrievable | 整合性チェック用 |
| `areaLabels` | Collection(Edm.String) | searchable, facetable | 駅名/ランドマーク等 |
| `vectorEmbedding` | Collection(Edm.Single) | searchable (vector, dim=1536) | OpenAI `text-embedding-3-small` |

除外: レビュー本文配列、画像配列など容量が大きいものは持たない。

## 3. シノニム/正規化

- シノニムマップ `synonyms-jp`: `カフェ,喫茶店 => cafe`, `レストラン,ダイナー => restaurant`, `バー,bar => bar` など。`tags`/`category` に適用。
- インジェスト時に tags を lower-case + 全半角正規化。空白・記号除去後に登録。

## 4. インジェスト設計

- ソース: Cosmos DB `stores` コンテナ Change Feed (`AllVersionsAndDeletes`)。
- 実装: Functions (Change Feed Trigger) で正規化 → Search `mergeOrUpload`。削除イベントは `@search.action=delete`。
- バッチ: 最大 100 ドキュメント/リクエスト、4MB 未満。`vectorEmbedding` は Functions 内で生成。
- ベクトル: Azure OpenAI `text-embedding-3-small`（1536次元, cosine）。`summary + tags + name` を結合して埋め込みを計算。
- 整合性: `cosmosEtag` を併送し、デバッグ時に Cosmos との差分を確認。

## 5. クエリ設計（主要ユースケース）

- マップ表示 `/stores?bounds=...&filters=...`: `geo.intersects(location, polygon)` + filter(`category`,`tags`,`wifi`,`power`,`priceRange`) + sort(`popularityScore desc`, fallback `rating desc`)。返却フィールドはピン描画に必要な最小集合。
- キーワード検索: `search=キーワード`（`ja.microsoft`）、`semanticConfiguration=semantic-default`、`searchMode=all`、上位50件。
- ハイブリッド検索: `vector` (k=20) + `search` 併用。`vectorEmbedding` 近傍を取得し、`popularityScore` で tie-break。
- サジェスト: `suggester=sg`、`searchFields=name,altNames,tags,areaLabels`、`fuzzy=true`、上限8件。
- 距離優先: `orderBy=geo.distance(location, geography'POINT(lon lat)') asc` を指定し、カフェ近傍表示を実現。

## 6. スコアリング/ランキング

- デフォルト順: `popularityScore desc` → `trendScore desc` → `rating desc` → `favoriteCount desc`。
- スコアリングプロファイル例 `score_popularity`: weights `{popularityScore:3.0, trendScore:1.5, rating:1.2}` + distance decay を追加して近場優先を実現。

## 7. 監視・運用

- メトリクス: インデックス件数、クエリ遅延、429/503 率、更新遅延（Change Feed時刻との差）、容量利用率。
- アラート: 更新遅延 >10分で Warning、>30分で Critical。容量利用率 80% 超で通知。
- リカバリ: 重大障害時は Cosmos 全件再送（再構築バッチ）＋ `vectorEmbedding` 再計算。Free 環境で容量超過する場合は即 Basic へ昇格。

## 8. 実装タスク

1. Search サービス作成 (Basic) と管理キーの Key Vault 登録。
2. 上記スキーマで `stores-index` を作成（semantic/vector/suggester/synonyms 設定含む）。
3. Change Feed Functions: 正規化 + ベクトル生成 + `mergeOrUpload`/`delete`、指数バックオフリトライ実装。
4. `/stores` API で Search クエリテンプレートを実装し、GeoJSON キャッシュ生成時に利用。
5. App Insights に Search 更新遅延・エラー率を記録し、アラートルールを適用。
