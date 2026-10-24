#!/bin/sh
# assert-secrets-present.tests.sh — exit 0 が全緑。陽性対照（在れば通る）と陰性対照（欠ければ落ちる）を対で置く。
set -eu
here=$(cd "$(dirname "$0")" && pwd)
sut="$here/../assert-secrets-present.sh"
pass=0; fail=0
ok() { _l=$1; shift; if env "$@" >/dev/null; then pass=$((pass+1)); else printf 'FAIL(合格するはずが落ちた): %s\n' "$_l" >&2; fail=$((fail+1)); fi; }
ng() { _l=$1; shift; if env "$@" >/dev/null; then printf 'FAIL(落ちるはずが合格した): %s\n' "$_l" >&2; fail=$((fail+1)); else pass=$((pass+1)); fi; }

ok '全部在れば通る'                 -i T_A=x T_B=y sh "$sut" T_A T_B
ng '1 つ欠ければ落ちる'             -i T_A=x       sh "$sut" T_A T_B
ng '空文字は欠けと同じ'             -i T_A=x T_B=  sh "$sut" T_A T_B
ng '名前 0 個は合格にしない'        -i             sh "$sut"
ng '不正な名前は落ちる（eval させない）' -i T_A=x  sh "$sut" 'T_A;echo'
out=$(env -i T_A=x sh "$sut" T_A T_B T_C || true)
case "$out" in *' T_B T_C') pass=$((pass+1)) ;; *) printf 'FAIL: 欠けた名前を全部出す: %s\n' "$out" >&2; fail=$((fail+1)) ;; esac
out=$(env -i T_A=supersecretvalue sh "$sut" T_A)
case "$out" in *supersecretvalue*) printf 'FAIL: 値を印字した\n' >&2; fail=$((fail+1)) ;; *) pass=$((pass+1)) ;; esac

printf 'assert-secrets-present: %s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
