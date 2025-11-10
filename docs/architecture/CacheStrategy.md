# キャッシュ戦略（ブラウザ / Edge / Cosmos 中心）

## 1. 目的
- Redis を撤去しつつ、Map描画・検索結果・お気に入り同期の体感速度を維持する。
- 無料枠主体の構成で月額コストを抑え、必要になればサーバ側メモリキャッシュやFront Doorを追加できる状態にする。

## 2. キャッシュレイヤ概要
| レイヤ | 対象 | 技術 | 役割 |
| --- | --- | --- | --- |
| ブラウザローカル | GeoJSONタイル、フィルタ状態、店舗詳細 | IndexedDB / LocalStorage | 即時レスポンス、オフライン補助。boundsハッシュごとに5〜10分保持。 |
| エッジ | 静的アセット、GeoJSON API | Static Web Apps (CDN) / Cache-Control | `Cache-Control: public,max-age=300` などでクラウド側キャッシュ。 |
| アプリ内（任意） | ホットデータ | Functions内メモリ (Durable cache) or App Service Cache (Basic Shared) | Redis代替。プロセスリサイクルに備えて短TTL (60秒)。 |
| データ永続化 | 店舗・口コミ・AI要約・お気に入り | Cosmos DB Serverless | 正規データソース。ETagで差分同期。 |

## 3. GeoJSON / Map描画
- フロントは bounds + filters を正規化したhash (`hash(latMin,latMax,lngMin,lngMax,zoom,filters)`) をキーにし、IndexedDBへ保存。
- APIレスポンスに `Cache-Control: public,max-age=300` を付与し、Static Web Apps/CDNヒットを狙う。Functions側ではCosmos検索のみ。
- キャッシュミス時だけCosmos + Cognitive Searchに問い合わせ、レスポンスサイズを20KB以下に抑制する。

## 4. 店舗詳細・Placesレスポンス
- 店舗詳細APIはCosmosのETagを返却。クライアントはETag一致時にローカルキャッシュを利用、差異がある場合のみ再取得。
- Places口コミはCosmosに保存し、`lastFetched` が24時間以内なら再利用。Google API呼び出しを最小化。

## 5. お気に入り同期
1. `/favorites` POSTで `etag` (前回の `FavoriteSync.etag`) を送信。Cosmos upsert後の新しいETagをレスポンス。
2. `/favorites?since=` で差分を取得し、LocalStorageを更新。SignalRは不要（ポーリングで十分）。
3. Functions内メモリキャッシュ（辞書）を使う場合はユーザーIDごとにTTL 60秒で保持し、Cosmos読み込み頻度を抑制。

## 6. サーバ側キャッシュ（オプション）
- どうしてもサーバでキャッシュしたい場合は以下を検討:
  - **Functions Durable cache**: インメモリ辞書 + `context.executionContext.functionName` に紐づくSingleton。コールドスタートやスケールアウト時はリセットされるためTTL短めに設定。
  - **Azure App Service Cache (Basic/Shared)**: $2〜$5/月。Redisより安価で、一時的にセッションやGeoJSONを保持できる。

## 7. 実装タスク
1. GeoJSON APIのレスポンスに `Cache-Control` ヘッダーを付与し、フロントでboundsハッシュ管理を実装。
2. `/stores/{id}` と `/favorites` のレスポンスにETagを含め、フロントでIf-None-Match/If-Matchヘッダーを設定。
3. Functionsに簡易メモリキャッシュ層を実装（有効時のみ）。必要な場合にApp Service Cacheへ切替できるよう抽象化。
4. Application Insightsで `cache_hit` / `cache_miss` を記録し、ヒット率が50%未満ならログをもとにTTLやキー設計を調整。

---
Redisを完全に撤去しても、上記のブラウザ＋エッジ＋Cosmos ETag方式でユーザー体験は維持できる。将来、負荷が増えた場合にのみRedisやFront Door Premiumを再導入する。
