#!/bin/bash
set -euo pipefail

# Extrai o nome do chart local
CHART_FILE="charts/my-app/Chart.yaml"
if [ ! -f "$CHART_FILE" ]; then
	echo "Falta $CHART_FILE" >&2
	exit 1
fi
CHART_NAME=$(awk -F": " '/^name:/{print $2; exit}' "$CHART_FILE" | tr -d '"')
if [ -z "$CHART_NAME" ]; then
	echo "Não foi possível ler o 'name' do Chart.yaml" >&2
	exit 1
fi

# Buscar index.yaml e extrair apenas a versão mais recente publicada (primeira entrada)
INDEX_URL="https://alexlopes.github.io/sre-playground/index.yaml"
LATEST_PUBLISHED=$(curl -s "$INDEX_URL" | yq -r ".entries[\"$CHART_NAME\"][0].version")
if [ -z "$LATEST_PUBLISHED" ] || [ "$LATEST_PUBLISHED" == "null" ]; then
	echo "Nenhuma versão publicada encontrada para '$CHART_NAME' em $INDEX_URL" >&2
	exit 1
fi

echo "$LATEST_PUBLISHED"