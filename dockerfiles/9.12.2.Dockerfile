ARG GHC_VERSION=9.12.2
ARG CABAL_VERSION=3.14.2.0
ARG STACK_VERSION=3.7.1
ARG LLVM_VERSION=20

ARG GHC_VERSION_BUILD=${GHC_VERSION}
ARG CABAL_VERSION_BUILD=${CABAL_VERSION}

FROM ghcr.io/loong64/ghc/ghc-musl:9.12.2-linux-loong64 AS bootstrap-cabal

FROM ghcr.io/loong64/alpine:3.23 AS ghc-base

ARG IMAGE_LICENSE="MIT"
ARG IMAGE_SOURCE="https://gitlab.b-data.ch/ghc/ghc-musl"
ARG IMAGE_VENDOR="Olivier Benz"
ARG IMAGE_AUTHORS="Olivier Benz <olivier.benz@b-data.ch>"

LABEL org.opencontainers.image.licenses="$IMAGE_LICENSE" \
      org.opencontainers.image.source="$IMAGE_SOURCE" \
      org.opencontainers.image.vendor="$IMAGE_VENDOR" \
      org.opencontainers.image.authors="$IMAGE_AUTHORS"

ARG GHC_VERSION_BUILD
ARG CABAL_VERSION_BUILD
ARG STACK_VERSION
ARG LLVM_VERSION

ENV GHC_VERSION=${GHC_VERSION_BUILD} \
    CABAL_VERSION=${CABAL_VERSION_BUILD} \
    STACK_VERSION=${STACK_VERSION} \
    LLVM_VERSION=${LLVM_VERSION}

RUN apk add --no-cache \
    bash \
    build-base \
    bzip2 \
    bzip2-dev \
    bzip2-static \
    clang${LLVM_VERSION} \
    curl \
    curl-static \
    dpkg \
    fakeroot \
    ghc-loongarch \
    git \
    gmp-dev \
    gmp-static \
    libcurl \
    libffi \
    libffi-dev \
    lld${LLVM_VERSION} \
    llvm${LLVM_VERSION} \
    ncurses-dev \
    ncurses-static \
    openssl-dev \
    openssl-libs-static \
    pcre \
    pcre-dev \
    pcre2 \
    pcre2-dev \
    perl \
    ## Install shadow for `stack --docker`
    shadow \
    wget \
    xz \
    xz-dev \
    zlib \
    zlib-dev \
    zlib-static

FROM ghc-base AS ghc-stage1

ARG GHC_NATIVE_BIGNUM

FROM ghc-stage1 AS ghc-stage2

## Install Cabal (the tool) built with the GHC bootstrap version
COPY --from=bootstrap-cabal /usr/bin/cabal /usr/local/bin/cabal

## Rebuild Cabal (the tool) with the GHC target version
RUN cabal update \
  && cabal install "cabal-install-$CABAL_VERSION" \
  && cabal install "stack-$STACK_VERSION"

FROM ghc-stage1 AS test

WORKDIR /usr/local/src

## Install Cabal (the tool) built with the GHC target version
COPY --from=ghc-stage2 /root/.local/bin/cabal /usr/local/bin/cabal

COPY Main.hs Main.hs

RUN ghc -static -optl-pthread -optl-static Main.hs \
  && file Main \
  && ./Main \
  ## Test cabal workflow
  && mkdir cabal-test \
  && cd cabal-test \
  && cabal update \
  && cabal init -n --is-executable -p tester -l MIT \
  && cabal run

FROM ghc-base

## Install GHC and Stack
COPY --from=ghc-stage1 /usr/local /usr/local

## Install Cabal (the tool) built with the GHC target version
COPY --from=ghc-stage2 /root/.local/bin/cabal /usr/local/bin/cabal
COPY --from=ghc-stage2 /root/.local/bin/stack /usr/local/bin/stack

CMD ["ghci"]
