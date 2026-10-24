#!/bin/sh
# assert-secrets-present.sh — 渡した名前の環境変数（＝GitHub Secret を env に写した物）が全部空でないことを判定する。
# 欠けたまま先へ進むと、落ちるのは 10 分後の jsign／keychain の step で、エラーは認証ライブラリの一般的な文言になる
# （「何が足りないか」がログから読めない）。⇒ 最初のジョブで**欠けている名前を出して**赤で落とす。
# ⛔ 「Secret が無いからスキップして緑」にはしない——配布物が出ていないのに緑は嘘である。
#
# 使い方: sh .github/scripts/assert-secrets-present.sh NAME1 NAME2 ...
#   全部在る → exit 0 ／ 1 つでも空 → exit 1（欠けた名前を 1 行 stdout へ）
# 🚨 値は読まない・印字しない。見るのは「空かどうか」だけ（`[ -n ]` の真偽のみ）。
# shellcheck shell=sh
set -u
[ "$#" -gt 0 ] || { echo '検査する Secret の名前が 0 個（0 件を合格にしない）'; exit 1; }
missing=''
for name in "$@"; do
    case "$name" in
        ''|*[!A-Za-z0-9_]*|[0-9]*) echo "Secret の名前として不正: '$name'"; exit 1 ;;
    esac
    eval "v=\${$name-}"
    [ -n "$v" ] || missing="$missing $name"
done
unset v
if [ -n "$missing" ]; then
    echo "missing repository secret(s):$missing"
    exit 1
fi
echo "required secrets present: $*"
