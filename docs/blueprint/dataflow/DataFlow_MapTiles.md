# データフロー: Map描画データ生成 / キャッシュ

## 1. 目的
- 地図表示エリアに応じて店舗データを高速に返し、Google Maps/Places への無駄なリクエストを削減する。
- Redis と Azure Front Door のキャッシュを前提に、GeoJSONレスポンスを最適化する。

## 2. シーケンス概要
```mermaid
sequenceDiagram
    participant Frontend as Frontend (Next.js)
    participant APIFunc as Azure Functions (HTTP /stores?bounds=)
    participant Redis as Azure Cache for Redis
    participant Cosmos as Cosmos DB
    participant Search as Azure Cognitive Search
    participant Monitor as App Insights

    Frontend->>APIFunc: GET /stores?bounds=...
    APIFunc->>Redis: Get geo:bounds:{hash(bounds)}
    alt Cache Hit
        Redis-->>APIFunc: Cached GeoJSON
    else Cache Miss
        APIFunc->>Search: Query by geo filter + tags
        Search-->>APIFunc: Store records
        APIFunc->>Cosmos: Fetch additional details (favorites, AI tags)
        APIFunc->>Redis: Set geo:bounds:{...} (TTL 5-10分)
    end
    APIFunc-->>Frontend: GeoJSON + メタ情報
    APIFunc->>Monitor: レイテンシ/キャッシュヒット率を記録
```

## 3. 詳細ステップ
1. **リクエスト受付**
   - フロントは地図表示範囲（緯度経度の矩形）とフィルタ条件をクエリパラメータで送信。Front Doorで短期キャッシュ可。

2. **キャッシュチェック**
   - Redisキー: `geo:bounds:{latMin}:{latMax}:{lngMin}:{lngMax}:{filtersHash}`。
   - ヒットの場合、GeoJSONレスポンスを即返却（TTL 5〜10分）。

3. **データ生成（キャッシュミス時）**
   - Azure Cognitive Searchで地理フィルタ＋タグ/設備の条件検索。
   - 必要に応じてCosmos DBから追加フィールド（AI要約、お気に入り件数）を取得。
   - GeoJSONを生成し、Redisに保存。

4. **レスポンス / フロント側描画**
   - ピン位置（lat/lng）、雰囲気タグ、混雑指標を含むGeoJSONを返す。
   - フロントはGoogle Maps JavaScript APIでピン描画、広告ピンには「広告」ラベルを付与。

5. **監視・アラート**
   - Application Insightsにキャッシュヒット率、レスポンスタイムを記録。
   - キャッシュミスが続く場合はTTLを延長 or bounds分割ロジックを調整。

## 4. フェイルバック
- Cognitive Search でエラー発生時はCosmos DBの簡易クエリで最低限の店舗一覧を返却。
- Redis障害時はメモリキャッシュをFallbackとして利用（Functionsインスタンス単位）。

## 5. TODO / 次アクション
1. GeoJSON生成ロジックを共通化し、テストを作成。
2. Front Door を導入する場合、Cache-Controlヘッダーを設定してエッジキャッシュを有効化。
3. キャッシュインターフェースを実装し、Boundsハッシュ・フィルタハッシュのアルゴリズムをドキュメント化。
4. キャッシュヒット率のメトリクスをダッシュボード化し、90%以上を目標とする。
