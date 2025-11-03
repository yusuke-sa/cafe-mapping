# Azure Cost Management 予算アラート設定手順

## 1. 目的と前提
- このアプリでは月額コストが約 $6 (約¥1,000) を想定しているが、SNS API の従量課金や Google Maps の利用状況によって変動するため、早期に異常な支出を検知する必要がある。
- 月額 ¥3,000 （約 $20）を上限とする予算を設定し、50% / 80% / 95% の閾値でメール通知を受ける構成を推奨する。
- Azure サブスクリプションの所有者、またはコスト管理ロールを付与されたアカウントで作業を行う。

## 2. Azure ポータルからの設定手順
1. <https://portal.azure.com/> にサインインし、左上のメニューから **「コスト管理 + 請求」** を開く。
2. 左側ナビゲーションで **「コスト管理」→「予算」** を選択し、右上の **「追加」** をクリック。
3. 以下の項目を入力し、**「次へ」** を選択する。
   - **名前**: `budget-iijan-map`
   - **範囲**: 対象サブスクリプション（1つのみ本番利用を想定）
   - **期間**: 月次 (Monthly)
   - **開始/終了日**: `2025-10-30` から無期限にする場合は終了日を未指定、または1年分 (例: 2026-12-31)
   - **金額**: 3,000 円 (または $20)
4. **「アラート条件の設定」** で以下の閾値と通知先を追加。
   - 50% 到達時: メール通知（個人メールアドレス）宛て。メッセージ例「利用料金が予算の 50% に達しました」。
   - 80% 到達時: メール通知 + 追加通知先（開発用共有メールや Teams の連絡先）を設定。
   - 95% 到達時: Action Group を利用してメール + 将来的には Logic Apps 等への拡張を計画。
5. **「レビュー + 作成」** を押して内容を確認し、**「作成」** を実行。成功メッセージが表示されれば設定完了。

## 3. アクショングループの作成（オプション）
95% などの高リスク閾値で SMS や Teams 通知を送る場合は、あらかじめアクショングループを作成しておく。
1. Azure ポータルで検索バーに「Action groups」と入力し、**「アクショングループ」** を開く。
2. **「作成」** をクリックし、名前・リソースグループ・リージョンを入力。
3. 通知タイプとして「メール/SMS/プッシュ/音声」を選択し、SMS 送信が必要なら携帯番号を登録。
4. **「Review + create」** → **「Create」** で完了。作成済みアクショングループを予算アラートの通知先として選択する。

## 4. Azure CLI / PowerShell での自動化例
スクリプトで同様の予算設定を行う場合は、Azure CLI の `az consumption budget` コマンドを利用する。  
以下は月額¥3,000、50%/80%/95% のアラートを設定する例。

```bash
az consumption budget create \
  --scope /subscriptions/<subscription-id> \
  --amount 3000 \
  --time-grain Monthly \
  --name budget-iijan-map \
  --start-date 2025-10-30 --end-date 2026-12-31 \
  --category cost \
  --notification threshold=0.5,operator=EqualTo,contactEmails=you@example.com \
  --notification threshold=0.8,operator=EqualTo,contactEmails=you@example.com,shared@example.com \
  --notification threshold=0.95,operator=EqualTo,contactEmails=you@example.com,actionGroup=/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/microsoft.insights/actionGroups/<action-group-name>
```

> `threshold` の値は 0〜1 の割合で指定する。`operator=EqualTo` にすると閾値到達時に通知が送られる（`GreaterThan` なども設定可能）。

## 5. 運用上のヒント
- 実際の月額コスト推移を週1回程度確認し、必要であれば予算額や閾値を調整する。
- Google Maps など別クラウドの請求もあるため、総コスト把握のために Google Cloud Billing のアラート設定も並行して行う。
- 無料クレジット期間中でも予算アラートは有効化し、無料枠消化後の課金発生を即時に把握できるようにする。
- 予算を超過した場合は、使用量が多いサービス（Cosmos DB の RU、OpenAI のトークン、Google Places API コールなど）をコスト分析から特定し、設定見直しやキャッシュ強化で抑制する。
- アラートメールは見落としがちなので、メールクライアントでフィルタを作り、重要メールとして扱うよう設定しておく。
