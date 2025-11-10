# データフロー: SNS収集 → AI要約 → 永続化

## 1. 背景
- InstagramやGoogle Placesなどの公開情報を統合し、雰囲気タグや要約を生成してCosmos DBに保存する。
- 参照ドキュメント: `architecture/ArchitectureCurrent.md`, `operations/meta/InstagramSetup.md`, `architecture/APIQuotaPlan.md`, `architecture/CacheStrategy.md`.

## 2. シーケンス概要
> 実行頻度: 週2回、各バッチ最大150投稿。Instagram APIは1秒1リクエスト/連続100件でウェイトを入れる（`architecture/APIQuotaPlan.md`）。

```mermaid
sequenceDiagram
    participant TimerFn as Azure Functions (Timer Trigger)
    participant IGAPI as Instagram Graph API
    participant OpenAI as Azure OpenAI
    participant Cosmos as Azure Cosmos DB
    participant Monitor as App Insights

    TimerFn->>IGAPI: 投稿データ取得 (差分/週2回)
    IGAPI-->>TimerFn: 投稿リスト (JSON)
    TimerFn->>OpenAI: 要約/タグ生成 (gpt-4o-mini)
    OpenAI-->>TimerFn: 要約テキスト/タグ
    TimerFn->>Cosmos: upsert 店舗ドキュメント (ETag更新)
    TimerFn->>Monitor: 成功/失敗ログ + メトリクス
```

## 3. 詳細ステップ
1. **トリガー & 差分抽出**
   - タイマートリガーFunctionsが週2回起動。
   - Instagram Graph APIを呼び出し、ハッシュタグやビジネスアカウントに紐づく最新投稿を取得。
   - 最終取得時刻をCosmosに保存し、差分のみ処理。

2. **データ整形**
   - 投稿本文、画像URL、位置情報、エンゲージメント数を構造化。
   - 1バッチあたり最大150投稿、クォータ余裕がない場合は更に50件ごとに分割し、1秒ウェイトを挟む。

3. **AI要約・タグ抽出**
   - Azure OpenAI (gpt-4o-mini) に要約プロンプトを送信。
   - 雰囲気タグ（例: “落ち着いた”“作業向け”）とレビュー要約を生成。1投稿につき最大1,000トークンを上限とする。
   - エラー時は最大3回リトライ、連続バッチ失敗でアラート。

4. **永続化**
   - Cosmos DBに upsert。ETagを更新し、クライアント側はIf-None-Match/If-Matchで差分取得。
   - Change Feedを介してCognitive Searchや他処理へ伝搬。

5. **キャッシュ更新**
   - サーバ側キャッシュは保持せず、CosmosのETag＋ブラウザIndexedDBでキャッシュ。
   - 画面はETagが一致した場合ローカルデータを使用し、不一致時のみ再取得。

6. **監視・アラート**
   - Application Insightsで成功/失敗を記録。
   - `architecture/APIQuotaPlan.md` のアラート設定に従い、Instagramのレート超過やOpenAIエラーを通知。

## 4. 留意点
- Metaのレート制限: 1秒1リクエスト以下、連続100リクエスト毎にウェイト。
- トークン管理: Azure Key Vaultに保管し、期限30日前にアラート。
- GDPR/プライバシー: 公開情報のみを扱い、引用時に出典表示。

## 5. 次のアクション
1. このシーケンスを `docs/product/Roadmap.md` の「データフロー/ETLシーケンス詳細化」タスクにリンク。
2. 具体的なFunctions実装（スケジューラ、プロンプトテンプレート、Cosmosスキーマ）を失敗時リトライ含め設計。
