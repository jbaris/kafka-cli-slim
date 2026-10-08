#!/bin/bash
# Genera kafka-cli-<version>-slim.tgz a partir del tgz oficial de Apache Kafka.
# Uso: ./build.sh [directorio_de_trabajo]
set -euo pipefail

KAFKA_VERSION=3.9.1
SCALA_VERSION=2.13
NAME=kafka_${SCALA_VERSION}-${KAFKA_VERSION}
URL=https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/${NAME}.tgz
OUT_DIR=$(pwd)
WORK=${1:-$(mktemp -d)}

# 1. Descargar el tgz oficial (se omite si ya existe en el directorio de trabajo)
mkdir -p "$WORK/download" "$WORK/extract" "$WORK/slim/kafka-cli/bin" "$WORK/slim/kafka-cli/libs" "$WORK/slim/kafka-cli/config"
[ -f "$WORK/download/$NAME.tgz" ] || curl -fSL -o "$WORK/download/$NAME.tgz" "$URL"

# 2. Descomprimir
tar -xzf "$WORK/download/$NAME.tgz" -C "$WORK/extract"
SRC="$WORK/extract/$NAME"
DST="$WORK/slim/kafka-cli"

# 3. Copiar solo lo necesario para kafka-topics.sh
cp "$SRC/bin/kafka-topics.sh" "$SRC/bin/kafka-run-class.sh" "$DST/bin/"
cp "$SRC/config/tools-log4j.properties" "$DST/config/"
for j in argparse4j jackson-annotations jackson-core jackson-databind jackson-dataformat-csv jackson-datatype-jdk8 jopt-simple kafka-clients kafka-server-common kafka-storage kafka-storage-api kafka-tools kafka-tools-api reload4j slf4j-api slf4j-reload4j; do
  cp "$SRC"/libs/$j-[0-9]*.jar "$DST/libs/"
done

# 4. Licencias de Apache Kafka (requeridas al redistribuir)
cp "$SRC/LICENSE" "$SRC/NOTICE" "$DST/"
cp -r "$SRC/licenses" "$DST/licenses"

# 5. Generar el tgz liviano
tar -czf "$OUT_DIR/kafka-cli-${KAFKA_VERSION}-slim.tgz" -C "$WORK/slim" kafka-cli
ls -l "$OUT_DIR/kafka-cli-${KAFKA_VERSION}-slim.tgz"
