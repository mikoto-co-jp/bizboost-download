# BizBoost ダウンロード（Windows・Mac）

BizBoost のセットアップ（Windows `BizBoostSetup.exe`・Mac `BizBoostSetup.dmg`）の公式ダウンロード置き場です。

## ダウンロード（常に最新版）

- **Windows**: https://github.com/mikoto-co-jp/bizboost-download/releases/latest/download/BizBoostSetup.exe
- **Mac**: https://github.com/mikoto-co-jp/bizboost-download/releases/latest/download/BizBoostSetup.dmg
- **SHA256（改ざん確認用）**: https://github.com/mikoto-co-jp/bizboost-download/releases/latest/download/SHA256SUMS.txt

> ⏳ **まだ GA の Release はありません。** 下の「実走前の宿題」が片付き、検証した pre-release を昇格させると上の URL が解決します。

## 仕組み（運用者向け）

3 本の workflow は `yamatovision/bluelamp-download` の同名ファイル（と `.github/scripts/**` の判定器・テスト）の**写し**です（板 #572・箱 n=3687）。
ビルド元は BlueLamp と同じ 1 つのコードベース `yamatovision/bluelamp-installer`（private）の `main` で、フォークではありません。

| workflow | 起動 | 作る物 |
|---|---|---|
| `release-macos.yml` | 手動 dispatch のみ | `build/build-mac.sh --brand bizboost` → 署名・公証・staple → pre-release `mac-<sha7>`（dmg） |
| `build-release.yml` | 手動 dispatch（schedule は当面コメントアウト） | `build/build.ps1 -Brand bizboost` → 署名 → `mac-<sha7>` の dmg を取り込み → pre-release `build-<sha7>`（exe・dmg・SUMS の 3 点） |
| `promote-release.yml` | 手動 dispatch のみ | 検証した `build-<sha7>` を GA（releases/latest）へ昇格。**GA を作る経路はこれ 1 本だけ** |

撃つ順: `gh workflow run release-macos -R mikoto-co-jp/bizboost-download` → `gh workflow run build-release -R mikoto-co-jp/bizboost-download` → 検証 → `gh workflow run promote-release -R mikoto-co-jp/bizboost-download -f tag=build-<sha7>`

BlueLamp 版との差分は次だけです（判定器・#655 の full SHA 固定と assert・#936 の pre-release 既定・dmg の取り込みの型は原本のまま）:

1. ブランドの引数（`-Brand bizboost`／`--brand bizboost`）
2. 成果物名（`BizBoostSetup.exe`／`BizBoostSetup.dmg`）
3. jsign の `--name`／`--url`
4. このリポの名前
5. Secret の事前検査（各 workflow の `preflight` ジョブ・判定器 `.github/scripts/assert-secrets-present.sh`）
6. `KEYCHAIN_PASSWORD` を Secret に置かず、`release-macos.yml` の job の中で使い捨ての乱数を作る（一時 keychain ごと job の最後に消える）
7. `build-release.yml` の `schedule:` を当面コメントアウト

- 認証: installer リポの read-only deploy key（Secret `INSTALLER_DEPLOY_KEY`）のみ。公開されるのはビルド済みの exe・dmg と SHA256 だけです
- GCP の Workload Identity の provider は `bizboost-download-provider`（このリポの repository_id 一致 かつ `ref == refs/heads/main`）。⇒ **dispatch は main からだけ通ります**（枝から撃つと `google-github-actions/auth` で落ちます）

## コード署名

`BizBoostSetup.exe` は **GlobalSign OV コードサイニング証明書 `CN=MIKOTO, K.K.`**、`BizBoostSetup.dmg` は **Developer ID Application: MIKOTO, K.K.** で署名されます。

🚨 **署名者は「株式会社命」であり、BizBoost の提供元表記（株式会社グローバルイノベーションズ）とは異なります。**
これは意図的な決定です（主君裁定 2026-09-02：GI 名義の証明書は取得しない）。

- Windows の秘密鍵は **GCP Cloud KMS の HSM 内**にあり、リポジトリにも GitHub Secret にも存在しません
- `codesign/full-chain.pem` は署名時に埋め込む証明書チェーン（**公開情報**）。`yamatovision/bluelamp-download` のものと**同一ファイル**です
- **署名構成の正本は `yamatovision/bluelamp-download` の `codesign/README.md`**（ここに写すと 2 つの説明が別々に古くなるので写していません）

## 🚧 実走前の宿題

| # | やること | 状態 |
|:-:|---|---|
| 1 | Secret の投入（`INSTALLER_DEPLOY_KEY`・`GCP_WORKLOAD_IDENTITY_PROVIDER`・`GCP_SIGNING_SERVICE_ACCOUNT`・`APPLE_CERTIFICATE`・`APPLE_CERTIFICATE_PASSWORD`・`APPLE_ID`・`APPLE_PASSWORD`・`APPLE_TEAM_ID`）。`KEYCHAIN_PASSWORD` は置かない | 済（2026-10-24） |
| 2 | Workload Identity の provider `bizboost-download-provider` を作り、署名 SA に workloadIdentityUser を付ける | 済（2026-10-24） |
| 3 | installer 側で Mac の build に brand を渡せるようにする（`build/build-mac.sh --brand bizboost`）。⚠️ installer は `ref: main` を引くので、これが installer の main に入るまで Mac 版は建たない | 未 |
| 4 | main から `release-macos` → `build-release` を 1 回ずつ dispatch して緑にする | 未 |
| 5 | 実機で検証した `build-<sha7>` を `promote-release` で GA にする | 未 |
| 6 | 緑になった後、`build-release.yml` の `schedule:` のコメントアウトを外す | 未 |

Secret が欠けていると、各 workflow の**最初のジョブ（preflight）で欠けている名前を出して赤で落ちます**。「Secret が無いのでスキップして緑」にはしません（配布物が出ていないのに緑は嘘なので）。
