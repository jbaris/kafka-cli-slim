# kafka-cli-slim

Paquete liviano (~12 MB) con solo lo necesario para correr `kafka-topics.sh` de Apache Kafka 3.9.1.
El tgz oficial pesa ~116 MB; la mayor parte son librerías que `kafka-topics.sh` no usa (por ejemplo `rocksdbjni`, 58 MB).

Sirve, por ejemplo, para correr el CLI de Kafka dentro de un contenedor y reproducir problemas del cliente Java
(como un `OutOfMemoryError` con una configuración SSL/SASL incorrecta) sin bajar el paquete completo.

## Uso

Requiere Java instalado.

```bash
wget https://github.com/jbaris/kafka-cli-slim/raw/main/kafka-cli-3.9.1-slim.tgz
tar -xzf kafka-cli-3.9.1-slim.tgz
cd kafka-cli/bin/
echo "security.protocol=${CAMEL_COMPONENT_KAFKA_SECURITY_PROTOCOL}" > client.properties
echo "sasl.mechanism=${CAMEL_COMPONENT_KAFKA_SASL_MECHANISM}" >> client.properties
echo "sasl.jaas.config=${CAMEL_COMPONENT_KAFKA_SASL_JAAS_CONFIG}" >> client.properties
echo "client.dns.lookup=use_all_dns_ips" >> client.properties
./kafka-topics.sh --bootstrap-server "${CAMEL_COMPONENT_KAFKA_BROKERS}" --command-config client.properties --list
```

## Cómo se generó el tgz

Todo el proceso está automatizado en [`build.sh`](build.sh). Los pasos exactos son:

1. Descargar el tgz oficial desde el archivo de Apache (el mirror `dlcdn.apache.org` solo guarda las versiones vigentes):

   ```bash
   curl -fSL -O https://archive.apache.org/dist/kafka/3.9.1/kafka_2.13-3.9.1.tgz
   ```

2. Descomprimirlo en un directorio nuevo:

   ```bash
   mkdir extract && tar -xzf kafka_2.13-3.9.1.tgz -C extract
   SRC=extract/kafka_2.13-3.9.1
   ```

3. Crear la estructura del paquete liviano y copiar solo lo necesario:

   ```bash
   DST=slim/kafka-cli
   mkdir -p $DST/bin $DST/libs $DST/config
   cp $SRC/bin/kafka-topics.sh $SRC/bin/kafka-run-class.sh $DST/bin/
   cp $SRC/config/tools-log4j.properties $DST/config/
   for j in argparse4j jackson-annotations jackson-core jackson-databind jackson-dataformat-csv jackson-datatype-jdk8 jopt-simple kafka-clients kafka-server-common kafka-storage kafka-storage-api kafka-tools kafka-tools-api reload4j slf4j-api slf4j-reload4j; do
     cp $SRC/libs/$j-[0-9]*.jar $DST/libs/
   done
   ```

   `kafka-topics.sh` ejecuta `org.apache.kafka.tools.TopicCommand` (jar `kafka-tools`) a través de `kafka-run-class.sh`.
   Esa clase necesita `kafka-clients`, `kafka-server-common`, `kafka-storage` (contiene `LogConfig`), `kafka-tools-api`,
   jackson, jopt-simple, argparse4j y slf4j/reload4j para logging.

4. Copiar las licencias de Apache Kafka (requeridas al redistribuir):

   ```bash
   cp $SRC/LICENSE $SRC/NOTICE $DST/
   cp -r $SRC/licenses $DST/licenses
   ```

5. Generar el tgz:

   ```bash
   tar -czf kafka-cli-3.9.1-slim.tgz -C slim kafka-cli
   ```

6. Verificar que funciona (requiere Java):

   ```bash
   mkdir verify && tar -xzf kafka-cli-3.9.1-slim.tgz -C verify
   verify/kafka-cli/bin/kafka-topics.sh --help
   ```

### Notas

- El proceso se probó con Java 21 (Corretto).
- No incluye `snappy`, `zstd` ni `lz4`; para listar topics no hacen falta. Si algún comando los necesitara, copiarlos desde `libs/` del paquete original.
- Para otra versión de Kafka, cambiar `KAFKA_VERSION` en `build.sh` y revisar los nombres de los jars, porque pueden variar entre versiones.

## Licencia

Este paquete redistribuye binarios de Apache Kafka, licenciados bajo Apache License 2.0.
Ver `LICENSE`, `NOTICE` y `licenses/` dentro del tgz.
