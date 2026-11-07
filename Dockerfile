FROM eclipse-temurin:21-jdk-jammy@sha256:4b1a74fbffbe6b4e7b6f0171a472478282fb463790a51edf10e465d578f22b69 AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg2; \
    curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" -o /tmp/sbt-signing-key.asc; \
    fingerprint="$(gpg --show-keys --with-colons /tmp/sbt-signing-key.asc | awk -F: '$1 == "fpr" { print $10; exit }')"; \
    test "$fingerprint" = "2EE0EA64E40A89B84B2DF73499E82A75642AC823"; \
    gpg --dearmor -o /usr/share/keyrings/sbt-archive-keyring.gpg /tmp/sbt-signing-key.asc; \
    echo "deb [signed-by=/usr/share/keyrings/sbt-archive-keyring.gpg] https://repo.scala-sbt.org/scalasbt/debian all main" > /etc/apt/sources.list.d/sbt.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends sbt; \
    rm -rf /var/lib/apt/lists/* /tmp/sbt-signing-key.asc

WORKDIR /app

COPY build.sbt ./
COPY project/ project/
RUN sbt update

COPY src/ src/
RUN sbt compile

FROM eclipse-temurin:21-jdk-jammy@sha256:4b1a74fbffbe6b4e7b6f0171a472478282fb463790a51edf10e465d578f22b69 AS runtime
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG SPARK_VERSION=4.1.4
ARG SPARK_DOWNLOAD_BASE=https://archive.apache.org/dist/spark
ARG HADOOP_VERSION=3
ARG HADOOP_NATIVE_VERSION=3.4.2
ARG HADOOP_AWS_SDK_V2_VERSION=2.57.10
ARG NETTY_VERSION=4.2.17.Final
ARG DERBY_VERSION=10.17.1.0
ARG SCALA_VERSION=2.13.17
ARG PYTHON_VERSION=3.12.16
ARG PY4J_VERSION=0.10.9.9
ARG PYTHON_SHA256=710c3e75dac8b2f258d9cd0f76e5c4c2e9175fac9e249c98901552f7cf33b7dd
ARG SPARK_SHA512=1461b6c425d290913e7be97bfec738abc843c663d177dc57e32b82874d20144ed67dcca692a57efc4e5b40d2f001ee0e9e0d2d7b088ae58f5378ecac92739076
ARG HADOOP_SHA512=79a383e156022d6690da359120b25db8146452265d92a4e890d9ea78c2078a01b661daf78163ee9b4acef7106b01fd5c8d1a55f7ad284f88b31ab3f402ae3acf

ENV SPARK_HOME=/opt/spark
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_COMMON_LIB_NATIVE_DIR=/opt/hadoop/lib/native
ENV HADOOP_NATIVE_VERSION=${HADOOP_NATIVE_VERSION}
ENV HADOOP_AWS_SDK_V2_VERSION=${HADOOP_AWS_SDK_V2_VERSION}
ENV NETTY_VERSION=${NETTY_VERSION}
ENV DERBY_VERSION=${DERBY_VERSION}
ENV SPARK_VERSION=${SPARK_VERSION}
ENV SCALA_VERSION=${SCALA_VERSION}
ENV PYTHON_VERSION=${PYTHON_VERSION}
ENV PY4J_VERSION=${PY4J_VERSION}
ENV HADOOP_OPTS="-Djava.library.path=/opt/hadoop/lib/native"
ENV LD_LIBRARY_PATH=/opt/hadoop/lib/native
ENV PATH="/opt/spark/bin:/opt/spark/sbin:${PATH}"
ENV PYTHONPATH="${SPARK_HOME}/python/lib/pyspark.zip:${SPARK_HOME}/python/lib/py4j-${PY4J_VERSION}-src.zip"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        bash curl tar procps netcat-openbsd \
        libsnappy1v5 liblz4-1 libzstd1 libbz2-1.0 liblzma5 libssl3 libisal2 \
        build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev libffi-dev liblzma-dev; \
    curl -fsSL "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" -o /tmp/python.tgz; \
    echo "${PYTHON_SHA256}  /tmp/python.tgz" | sha256sum --check --strict -; \
    mkdir -p /tmp/python-src; \
    tar -xzf /tmp/python.tgz -C /tmp/python-src; \
    cd "/tmp/python-src/Python-${PYTHON_VERSION}"; \
    ./configure --prefix=/usr/local; \
    make -j"$(nproc)"; \
    make altinstall; \
    ln -sf /usr/local/bin/python3.12 /usr/bin/python3; \
    ln -sf /usr/local/bin/pip3.12 /usr/bin/pip3; \
    python3 --version; \
    rm -rf /tmp/python.tgz /tmp/python-src

# Keep Kubernetes submission support; remove unused Connect client and YARN shuffle artifacts.
RUN set -eux; \
    curl -fsSL "${SPARK_DOWNLOAD_BASE}/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -o /tmp/spark.tgz; \
    echo "${SPARK_SHA512}  /tmp/spark.tgz" | sha512sum --check --strict -; \
    tar -xzf /tmp/spark.tgz -C /opt; \
    mv "/opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" "${SPARK_HOME}"; \
    test -f "${SPARK_HOME}/python/lib/pyspark.zip"; \
    test -f "${SPARK_HOME}/python/lib/py4j-${PY4J_VERSION}-src.zip"; \
    hadoop_api_jar="$(find "${SPARK_HOME}/jars" -maxdepth 1 -type f -name 'hadoop-client-api-*.jar' -print -quit)"; \
    test -n "$hadoop_api_jar"; \
    distribution_hadoop_version="${hadoop_api_jar##*/hadoop-client-api-}"; \
    distribution_hadoop_version="${distribution_hadoop_version%.jar}"; \
    printf 'Spark distribution Hadoop client version: %s\n' "$distribution_hadoop_version"; \
    test "$distribution_hadoop_version" = "$HADOOP_NATIVE_VERSION"; \
    rm -f "${SPARK_HOME}"/jars/netty-*-4.2.7.Final*.jar \
        "${SPARK_HOME}"/jars/bundle-*.jar \
        "${SPARK_HOME}"/jars/derby*.jar \
        "${SPARK_HOME}/jars/connect-repl/spark-connect-client-jvm_2.13-${SPARK_VERSION}.jar" \
        "${SPARK_HOME}/jars/connect-repl/spark-connect-client-jdbc_2.13-${SPARK_VERSION}.jar" \
        "${SPARK_HOME}/bin/spark-connect-shell" \
        "${SPARK_HOME}/yarn/spark-${SPARK_VERSION}-yarn-shuffle.jar"; \
    rm -f /tmp/spark.tgz

RUN set -eux; \
    curl -fsSL "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_NATIVE_VERSION}/hadoop-${HADOOP_NATIVE_VERSION}.tar.gz" -o /tmp/hadoop.tgz; \
    echo "${HADOOP_SHA512}  /tmp/hadoop.tgz" | sha512sum --check --strict -; \
    mkdir -p /tmp/hadoop-src /opt/hadoop/lib/native /opt/hadoop/lib; \
    tar -xzf /tmp/hadoop.tgz -C /tmp/hadoop-src; \
    cp -a "/tmp/hadoop-src/hadoop-${HADOOP_NATIVE_VERSION}/lib/native/." "${HADOOP_HOME}/lib/native/"; \
    cp "/tmp/hadoop-src/hadoop-${HADOOP_NATIVE_VERSION}/share/hadoop/common/hadoop-common-${HADOOP_NATIVE_VERSION}.jar" "${HADOOP_HOME}/lib/"; \
    rm -rf /tmp/hadoop.tgz /tmp/hadoop-src

COPY scripts/*.sh /
RUN chmod +x /*.sh

COPY --from=build /app/target/lib/*.jar ${SPARK_HOME}/jars/
COPY scripts/ci/check-runtime-jars.py /tmp/check-runtime-jars.py
RUN python3 /tmp/check-runtime-jars.py \
      --spark-jars "${SPARK_HOME}/jars" \
      --expected-hadoop "${HADOOP_NATIVE_VERSION}" \
      --expected-aws-sdk-v2 "${HADOOP_AWS_SDK_V2_VERSION}" \
      --expected-netty "${NETTY_VERSION}" \
      --expected-derby "${DERBY_VERSION}" && \
    rm -f /tmp/check-runtime-jars.py

RUN set -eux; \
    apt-get purge -y build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev libffi-dev liblzma-dev; \
    apt-get autoremove -y; \
    apt-get clean; \
    rm -rf /root/.cache/pip /var/lib/apt/lists/*

CMD ["bash"]
