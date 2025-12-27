#!/bin/bash
set -euo pipefail

# Arquivo Chart
CHART_FILE="charts/my-app/Chart.yaml"

# 1) Ler versão atual
current_version=$(awk -F": " '/^version:/{print $2; exit}' "$CHART_FILE" | tr -d '"')
if [ -z "$current_version" ]; then
	echo "Falha: não foi possível ler 'version' em $CHART_FILE" >&2
	exit 1
fi

# 2) Incrementar o último segmento numérico (ex: 0.1.6 -> 0.1.7)
IFS='.' read -r -a parts <<< "$current_version"
last_idx=$(( ${#parts[@]} - 1 ))
if ! [[ ${parts[$last_idx]} =~ ^[0-9]+$ ]]; then
	echo "Falha: último segmento da versão não é numérico: ${parts[$last_idx]}" >&2
	exit 1
fi
parts[$last_idx]=$(( parts[$last_idx] + 1 ))
NEXT_VERSION="${parts[0]}"
for i in "${parts[@]:1}"; do
	NEXT_VERSION+=".$i"
done

# 3) Atualizar Chart.yaml com a nova versão
awk -v v="$NEXT_VERSION" 'BEGIN{OFS=FS} /^version:/{print "version: " v; next} {print}' "$CHART_FILE" > "${CHART_FILE}.tmp" && mv "${CHART_FILE}.tmp" "$CHART_FILE"

export NEXT_VERSION
echo "Bumped version: $current_version -> $NEXT_VERSION"

# Empacota e atualiza índice
helm package charts/my-app
helm repo index . --url https://alexlopes.github.io/sre-playground

# Commit das mudanças
git add "$CHART_FILE" .
if git commit -m "Bump to $NEXT_VERSION"; then
	git push origin main
else
	echo "Aviso: nenhum commit realizado (talvez não haja alterações)." >&2
fi