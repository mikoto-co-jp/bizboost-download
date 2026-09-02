# BizBoost ダウンロード（Windows）

BizBoost の Windows セットアップ（`BizBoostSetup.exe`）の公式ダウンロード置き場です。

## ダウンロード（常に最新版）

- **インストーラ本体**: https://github.com/mikoto-co-jp/bizboost-download/releases/latest/download/BizBoostSetup.exe
- **SHA256（改ざん確認用）**: https://github.com/mikoto-co-jp/bizboost-download/releases/latest/download/SHA256SUMS.txt

> ⏳ **まだ Release はありません。** 下の「実走前の宿題」が片付いてから最初のビルドを回します。

## 仕組み（運用者向け）

- ビルド元: `yamatovision/bluelamp-installer`（private）の `main`。**BlueLamp と同じ 1 つのコードベース**から
  `build/build.ps1 -Brand bizboost` でビルドします（板 #572・フォークではありません）
- `.github/workflows/build-release.yml` が windows ランナー＋Inno Setup でビルドし、
  GlobalSign OV 証明書で署名し、このリポジトリの Release（tag: `build-<sha7>`）として公開します
- トリガー: 手動 `gh workflow run build-release -R mikoto-co-jp/bizboost-download`
  （毎朝の自動リリースは**意図的に無効化中**。理由は下記）
- 認証: installer リポの read-only deploy key（Secret `INSTALLER_DEPLOY_KEY`）のみ。
  ソースコードは公開されません（公開されるのはビルド済み exe と SHA256 のみ）

この workflow は `yamatovision/bluelamp-download` の `build-release.yml` の**写し**です。
BlueLamp 版との差分は 4 点だけ（ビルド引数・成果物名・jsign の `--name`/`--url`・Secret 事前検査）で、
**署名まわり（keystore / alias / certfile / TSA / alg）は 1 文字も変えていません**。

## コード署名

`BizBoostSetup.exe` は **GlobalSign OV コードサイニング証明書 `CN=MIKOTO, K.K.`** で署名されます。

🚨 **署名者は「株式会社命」であり、BizBoost の提供元表記（株式会社グローバルイノベーションズ）とは異なります。**
これは意図的な決定です（主君裁定 2026-09-02：GI 名義の証明書は取得しない）。
Windows の UAC ダイアログと証明書のプロパティには `MIKOTO, K.K.` が表示されます。

- 秘密鍵は **GCP Cloud KMS の HSM 内**にあり、リポジトリにも GitHub Secret にも存在しません。
  CI は Workload Identity 連携で一時トークンを得て、KMS に署名を依頼するだけです
- `codesign/full-chain.pem` は署名時に埋め込む証明書チェーン（**公開情報**なので Secret ではありません）。
  `yamatovision/bluelamp-download` のものと**同一ファイル**です（同じ証明書で署名するため）
- **署名構成の正本は `yamatovision/bluelamp-download` の `codesign/README.md`**（証明書の有効期限・鍵のパス・
  更新手順）。ここに写すと 2 つの説明が別々に古くなるので、意図的に写していません

## 🚧 実走前の宿題（このリポジトリではまだ 1 度もビルドしていません）

| # | やること | 手番 | 状態 |
|:-:|---|---|---|
| 1 | Secret 3 本の投入（`INSTALLER_DEPLOY_KEY` / `GCP_WORKLOAD_IDENTITY_PROVIDER` / `GCP_SIGNING_SERVICE_ACCOUNT`）。値は `bluelamp-download` と同じ | CTO | 未 |
| 2 | **Workload Identity 連携の許可対象にこのリポジトリを追加する** | CTO | 未 |
| 3 | 手動 dispatch を 1 回グリーンにする | — | 未 |
| 4 | グリーン後、`build-release.yml` の `schedule:` のコメントアウトを外す | — | 未 |

🚨 **#2 は見落としやすく、Secret を入れただけでは通らない可能性が高い**論点です。
GitHub Actions の Workload Identity プロバイダは、たいてい
`assertion.repository == 'yamatovision/bluelamp-download'` のような attribute condition で
**特定リポジトリに縛られています**。縛られていれば、同じ Secret を入れても
このリポジトリからの認証は **GCP 側で拒否** されます（症状は `google-github-actions/auth` ステップでの失敗）。
**未検証**です — このリポジトリからは GCP の設定を読めないため、CTO 手番として残します。

なお workflow は Secret が欠けていると**最初のジョブで欠けている名前を出して赤で落ちます**。
「Secret が無いのでスキップして緑」にはしません（配布物が出ていないのに緑は嘘なので）。
