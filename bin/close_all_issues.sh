#!/opt/homebrew/bin/bash
#
# close_all_issues.sh
# -------------------
# 指定リポジトリ（省略時はカレントディレクトリの GitHub origin）で
# Open 状態の Issue をすべて Close します。
#
# 使い方:
#   ./close_all_issues.sh               # カレント repo の Issue を全閉
#   ./close_all_issues.sh owner/repo    # 明示的に指定
#

set -euo pipefail

# ────────────────────────────────
# 対象リポジトリ
# ────────────────────────────────
REPO=${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}

# ────────────────────────────────
# Open Issue 番号一覧を取得（最大 1000 件）
# ────────────────────────────────
mapfile -t ISSUE_NUMBERS < <(
  gh issue list --repo "$REPO" --state open --limit 1000 --json number -q '.[].number'
)

if (( ${#ISSUE_NUMBERS[@]} == 0 )); then
  echo "✅ $REPO には Open Issue がありません。"
  exit 0
fi

echo "⚠️  $REPO の Open Issue を ${#ISSUE_NUMBERS[@]} 件クローズします。"
read -r -p "続行しますか？ [y/N]: " ans
[[ "$ans" =~ ^[Yy]$ ]] || { echo "中止しました。"; exit 1; }

# ────────────────────────────────
# Issue を順にクローズ
# ────────────────────────────────
for num in "${ISSUE_NUMBERS[@]}"; do
  printf "  #%-5s ... " "$num"
  gh issue close "$num" --repo "$REPO" \
    --comment "Bulk closed via close_all_issues.sh" >/dev/null
  echo "done"
done

echo "🎉  全 Issue をクローズしました。"
