FROM ghcr.io/leanprover/lean4:v4.9.0

# Fix 2 (Nova): One Docker for the whole trinity
# Lean 4 + Python + Scala/Dex pinned — anyone can reproduce

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3=3.10.6-1~22.04 \
    python3-pip=22.0.2+dfsg-1 \
    curl wget \
    && rm -rf /var/lib/apt/lists/*

# Scala 3 + sbt
RUN curl -fL https://github.com/coursier/coursier/releases/download/v2.1.10/cs-x86_64-pc-linux.gz \
    | gzip -d > /usr/local/bin/cs && chmod +x /usr/local/bin/cs
RUN cs setup --yes && cs install scala:3.3.3 sbt:1.9.8

# Python crypto libs — pinned
COPY python/requirements.lock /tmp/requirements.lock
RUN pip3 install --no-cache-dir -r /tmp/requirements.lock

WORKDIR /aes-formal
COPY lean-toolchain lakefile.lean* ./
RUN lake update && lake build

COPY . .

CMD ["sh", "reproduce.sh"]
