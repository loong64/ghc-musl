ARG GHC_VERSION=9.12.2
ARG CABAL_VERSION=3.16.1.0

ARG GHC_VERSION_BUILD=${GHC_VERSION}
ARG CABAL_VERSION_BUILD=${CABAL_VERSION}

FROM ghcr.io/loong64/alpine:3.23 AS bootstrap

ARG GHC_VERSION_BUILD
ARG CABAL_VERSION_BUILD

ENV CABAL_VERSION=${CABAL_VERSION_BUILD}
ENV GHC_VERSION=${GHC_VERSION_BUILD}

RUN apk add --no-cache \
    autoconf \
    automake \
    binutils \
    build-base \
    coreutils \
    cpio \
    curl \
    ghc-loongarch \
    gnupg \
    linux-headers \
    libffi-dev \
    ncurses-dev \
    perl \
    python3 \
    xz \
    zlib-dev

RUN cd /tmp/ \
    && curl -sSLO https://github.com/haskell/cabal/archive/refs/tags/cabal-install-v$CABAL_VERSION.tar.gz \
    && tar zxf cabal-install-v$CABAL_VERSION.tar.gz \
    && cd /tmp/cabal-cabal-install-v$CABAL_VERSION \
    && ./bootstrap/bootstrap.py -d ./bootstrap/linux-${GHC_VERSION}.json \
    && cp -f _build/bin/cabal /usr/local/bin/cabal

FROM ghcr.io/loong64/alpine:3.23

LABEL org.label-schema.license="MIT" \
      org.label-schema.vcs-url="https://gitlab.b-data.ch/ghc/ghc4pandoc" \
      maintainer="Olivier Benz <olivier.benz@b-data.ch>"

ARG GHC_VERSION_BUILD
ARG CABAL_VERSION_BUILD

ENV GHC_VERSION=${GHC_VERSION_BUILD}
ENV CABAL_VERSION=${CABAL_VERSION_BUILD}

RUN apk add --no-cache \
    bash \
    build-base \
    bzip2 \
    bzip2-dev \
    #bzip2-static \
    curl \
    curl-static \
    fakeroot \
    ghc-loongarch \
    git \
    gmp-dev \
    libcurl \
    libffi \
    libffi-dev \
    ncurses-dev \
    ncurses-static \
    openssl-dev \
    #openssl-libs-static \
    pcre \
    pcre-dev \
    pcre2 \
    pcre2-dev \
    perl \
    wget \
    xz \
    xz-dev \
    zlib \
    zlib-dev
    #zlib-static

COPY --from=bootstrap /usr/local/bin/cabal /usr/bin/cabal

CMD ["ghci"]
