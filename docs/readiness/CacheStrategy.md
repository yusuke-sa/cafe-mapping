# キャッシュ戦略メモ（Redis / Front Door 前提）

## 1. 目的
- Map描画や検索結果を高速化し、Google Maps/Places API の呼び出し回数を削減する。
- 将来的なユーザー増加時にAzure Front Door / Azure Cache for Redisを導入しやすい設計を固める。
- お気に入り等のユーザー関連データをCosmos DB＋Redisでマルチデバイス同期できるようにする。

## 2. キャッシュレイヤ概要
| レイヤ | 対象 | 技術 | 役割 |
| --- | --- | --- | --- |
| ブラウザローカル | 地図タイルキャッシュ（Google提供）、短期設定・フィルタ状態 | LocalStorage / IndexedDB | 即時レスポンス、オフライン補助 |
| エッジ | 画像/CSS/JS、Map初期GeoJSON | Azure Front Door + Static Web Apps | CDNで初期ロードを高速化 |
| アプリ内キャッシュ | 店舗リスト、GeoJSON、AI要約 | Azure Cache for Redis (Standard C0〜) | Functionsのレスポンス高速化 |
| データ永続化 | 店舗メタ、レビュー要約、お気に入り同期 | Cosmos DB Serverless | 正規データソース |

## 3. Redis キャッシュ設計案
- **キー命名規則**
  - `geo:bounds:{latMin}:{latMax}:{lngMin}:{lngMax}` … 地図表示領域ごとの店舗配列。
  - `store:{storeId}:detail` … 店舗詳細＋AI要約。
  - `user:{userId}:favorites` … お気に入りID一覧（Cosmosをバックエンドとし、Redisは読み取りキャッシュ）。
  - `meta:places:{placeId}` … Google Places APIレスポンスのキャッシュ。
- **TTL 方針**
  - 地図領域: 5〜10分（人気スポット更新に追従しつつ Places API 呼び出しを抑制）。
  - 店舗詳細: 1時間（AI要約再生成や営業時間更新頻度次第で調整）。
  - お気に入り: 1分（ほぼリアルタイム反映、同期衝突を最小化）。
  - Placesレスポンス: 24時間以内で再取得（Googleポリシーに準拠）。
- **ライトスルー/ライトビハインド**
  - ユーザーお気に入り操作はまずCosmos DBに書き込み、その結果をRedisに反映（ライトスルー）。
  - バッチ処理でPlaces等を取得した際はRedisにも保存し、Functions/Front Doorから参照。

## 4. Front Door / CDN 設計
- Azure Front Door をStatic Web Appsの前段に置き、地理的に近いエッジからNext.js静的アセットを配信。
- APIレスポンス（地図領域ごとのGeoJSON）もFront Doorで短時間キャッシュする（Cache-Controlヘッダーで5分程度）。
- 認証付きAPIはFront Doorでキャッシュせず、FunctionsでRedisヒットを狙う。

## 5. マルチデバイス同期（お気に入り）
1. お気に入り追加/削除をFunctions APIへ送信 → Cosmos DBに永続化。
2. Cosmos DB Change Feed で更新イベントを取得し、Redis `user:{userId}:favorites` を更新。
3. フロントは起動時にCosmosからフル同期（もしくはFunctions APIがRedisから取得）。
4. LocalStorageとは別に、最終同期時刻を保持し、差分同期APIを提供（例: `/favorites?since=...`）。
5. 将来的にリアルタイム性が必要ならAzure SignalR Serviceを併用し、他デバイスへプッシュ通知。

## 6. 実装タスク案
1. Functionsレスポンス用のキャッシュインターフェースを作成（Redis未導入時はメモリスタブ）。
2. マップ領域ごとのGeoJSON生成APIにキー設計を適用し、URQL等でキャッシュ利用。
3. お気に入りAPIをCosmos書き込み→Redis更新のライトスルー構成に変更し、マルチデバイス同期を実装。
4. Front Door導入時にCache Rules/ヘッダー設定をドキュメント化。
5. Places/APIクォータ計画と連携し、キャッシュヒット率をモニタリング（Application Insights + Redis Metrics）。

---
これらをフェーズ1（設計見直し）でドキュメント化し、必要に応じてフェーズ2以降で実装する。
