# アカウント・ライセンス整備メモ

## 1. サマリ
本アプリのMVP運用にあたり、以下の主要サービスでアカウント作成や利用申請、ライセンス確認が必要。  
AzureとGoogle Cloudは課金アカウントの開設が前提となり、SNS由来データの取得には各プラットフォームの開発者ポリシー遵守と追加手続きが伴う。

## 2. 必須アカウント一覧

| 区分 | サービス | アカウント種別 | 主な手続き | 注意点 / ライセンス |
| --- | --- | --- | --- | --- |
| クラウド基盤 | Microsoft Azure | 個人/法人向け Azure サブスクリプション (Pay-As-You-Go 推奨) | Microsoft アカウント作成 → サブスクリプション契約 → クレジットカード登録 | 東日本リージョン利用には標準課金。学生/スタートアップ向けクレジットがあれば活用。 |
| AIサービス | Azure OpenAI Service | Azure サブスクリプション上の追加申請 | [Azure OpenAI 申請フォーム](https://aka.ms/oai/access) へ利用目的を記載し申請。承認後に対象リージョンでリソース作成 | 承認には数営業日〜数週間。利用規約とコードオブコンダクト順守。日本リージョンでの提供状況を事前確認。 |
| マップ/位置情報 | Google Maps Platform (Maps JavaScript / Places API) | Google Cloud プロジェクト + 請求アカウント | Google アカウント → Google Cloud Console でプロジェクト作成 → 請求アカウント登録 → API有効化 → APIキー発行 | 月額$200の無料クレジットあり。利用規約（表示義務・データ保持制限）遵守。APIキーは制限設定必須。 |
| SNSデータ | Instagram Graph API | Meta for Developers アカウント + Instagram ビジネス/クリエイターアカウント | Facebook (Meta) 開発者登録 → アプリ作成 → Instagram ビジネス/クリエイターアカウントとFacebookページを連携 → アクセストークン発行 | 商用利用はポリシー遵守、アプリ審査が必要な権限あり。公開前に審査提出を想定。 |
| SNSデータ (任意) | TikTok API for Business | TikTok for Developers / Business アカウント | TikTok for Developers 登録 → アプリ申請 → 審査後にAPIキー発行 | 取得できるデータ範囲が限定的。用途説明が必要。 |
| SNSデータ (任意) | X (旧Twitter) API | X Developer アカウント (有料プラン) | Developer アカウント申請 → Basicプラン($100/月)等に加入 → APIキー取得 | 無料枠が小さく、コストに注意。利用規約でスクレイピング・加工に制約。 |
| DevOps | GitHub | GitHub個人アカウント | GitHubサインアップ → リポジトリ作成 → Actions有効化 | 無料枠で十分。プライベートRepoはFreeプランで利用可。 |

## 3. 詳細メモ

### 3.1 Microsoft Azure
- **必須リソース**: Static Web Apps, Functions, Cosmos DB, Cognitive Search, Storage, Monitor, Data Factoryなど。1つのサブスクリプション内で管理可能。
- **課金設定**: クレジットカード登録後、必要に応じてコストアラート設定（Azure Cost Management）。個人利用でも月額請求が発生し得るため、支出上限アラート推奨。
- **Azure OpenAI**: 一般提供リージョンのみ利用可能。日本リージョン（East Japan）は提供状況が変わる可能性があるため、近隣リージョン（East US, West Europe等）を選択する場合がある。

### 3.2 Google Maps Platform
- **有効化API**: Maps JavaScript API、Places API（Details、Autocomplete）、Geocoding（必要に応じて）。
- **請求要件**: プロジェクトごとに請求アカウントを紐づけ、月額無料クレジットを超えた分が課金。個人利用でもクレジットカード登録が必要。
- **ライセンス注意**: Google Mapsの地図タイルやPOIデータを独自キャッシュする行為は制限。利用ポリシー上、表示にはGoogleマップロゴ等の帰属表示が必須。
- **口コミ取得**: Places Details APIで各店舗につき最大5件のユーザーレビューが取得可能。保存・再配布はポリシー上限定的で、引用時はレビュアー名・投稿日など付随情報を含む必要がある。長期保存はキャッシュ方針を確認し、最新データ取得を基本とする。

### 3.3 Instagram Graph API (Meta)
- **アカウント要件**: Instagram ビジネスまたはクリエイターアカウント、Facebookページ、Meta開発者アカウントが必要。個人アカウントからビジネスアカウントへの移行が前提。
- **権限申請**: `instagram_basic`, `pages_show_list`, `instagram_manage_insights`など必要な権限に応じてアプリ審査を受ける。審査では利用用途の説明資料・動画が求められる場合あり。
- **レート制限**: ビジネスアカウント単位で制限があるため、取得頻度を調整。規約上、投稿内容の再配布・保存に制約があり、引用表示や著作権対応が必要。

### 3.4 TikTok / X API（任意）
- **TikTok**: 公開APIで取得できるのは限定的。マーケティング用途に特化。用途に応じて別途Business Centerの承認が必要な場合あり。
- **X API**: 2023年以降、無料アクセスは極めて限定的。検索系エンドポイントは有料プランでのみ利用可能。費用対効果を検討のうえ導入可否を判断。

### 3.5 GitHub
- **用途**: ソース管理、ActionsによるCI/CD。無料プランでプライベートリポジトリが利用できる。外部サービス（Azure DevOps等）と連携する場合はPAT発行に注意。

## 4. アクションチェックリスト
1. MicrosoftアカウントでAzureサブスクリプションを発行し、支払い情報を設定。
2. Azure OpenAIの利用申請フォームに必要事項を記入し、承認通知を待つ（想定数週間）。
3. GoogleアカウントでGoogle Cloudプロジェクトを作成、請求アカウントとMaps/Places APIを有効化、APIキーを発行してIP/HTTPリファラ制限を設定。
4. Meta for Developersで開発者登録し、Instagramビジネスアカウント＋Facebookページを紐付け、アプリ作成および必要権限の審査準備。
5. 使用予定の追加SNS API（Yelp/TikTok/Xなど）があれば各プラットフォームで開発者登録し、規約・料金を精査。
6. GitHubのプライベートリポジトリを用意し、CI/CD用にActionsを有効化。必要に応じてAzureとシークレット連携。
7. 各プラットフォームで利用規約・ブランドガイドラインを保管し、アプリ内の表示ポリシーに反映。

## 5. 補足事項
- 取得したデータ（投稿テキスト・画像）の保存・再利用については各利用規約に基づき、必要に応じて引用元表示や削除リクエスト対応フローを整備する。
- 個人利用規模であっても、Google MapsやInstagramは課金/審査の前提を満たす必要がある。早期にアカウント準備を進めることで開発着手後のブロッカーを減らせる。
- 外部APIは提供仕様が変化するため、定期的な利用規約・料金の確認を推奨。
