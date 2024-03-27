FROM amazonlinux:2

LABEL maintainer="Khartes Geoinformação <contato@khartes.com.br>"
LABEL authors="Diego Moreira  <diego@khartes.com.br>, Alisson Palmeira  <alisson@khartes.com.br>"

# Install build dependencies
RUN yum update -y; \
    yum groupinstall "Development Tools" -y; \
    yum install -y \
	    automake \
        bzip2 \
        bzip2-devel \
        cpanminus \
        gcc \
        gcc-c++ \
        gzip \
        libffi-devel \
        libpsl-devel \
        libtool \
        lzma \
        make \
        ncurses-devel \
        readline-devel \
        rsync \
        tar \
        tkinter \
        uiid \
        wget \
        zip \
        zlib-devel

RUN cpanm IPC::Cmd

# Define environment variables for versions
ENV GDAL_VERSION=3.8.4 \
	PROJ_VERSION=9.0.1 \
	GEOS_VERSION=3.9.5 \
	TIFF_VERSION=4.6.0 \
	CURL_VERSION=8.6.0 \
	NGHTTP2_VERSION=1.60.0 \
	SQLITE_VERSION=3450200 \
	CMAKE_VERSION=3.27.1 \
	OPENSSL_VERSION=3.2.1 \
	PYVERSION=3.12.2

# Paths to things
ENV \
    BUILD=/build \
    NPROC=8 \
    PREFIX=/usr/local \
    LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64 \
    GDAL_CONFIG=/usr/local/bin/gdal-config \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib64/pkgconfig \
    GDAL_DATA=/usr/local/share/gdal \
    PROJ_LIB=/usr/local/share/proj

# switch to a build directory
WORKDIR $BUILD


# Download and compile OpenSSL
RUN yum remove openssl -y; \
    mkdir openssl; \
    # Download and extract OpenSSL
    wget -qO- https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
        | tar xvz -C openssl --strip-components=1; \
    cd openssl; \
    # Configure and compile OpenSSL
    ./config --prefix=$PREFIX/ssl --openssldir=$PREFIX/ssl shared zlib; \
    make depend -j ${NPROC}; \
    make install; \
    # Return to the previous directory and clean up
    #   cd .. rm -rf openssl;  falta um ponto e vírgula (;) entre os comandos cd .. e rm -rf openssl
    cd ..; rm -rf openssl;

    
ENV \
    PATH="$PREFIX/ssl/bin:$PATH" \
    LD_LIBRARY_PATH="$PREFIX/ssl/lib64:$LD_LIBRARY_PATH" \
    OPENSSL_CONF="$PREFIX/ssl/openssl.cnf"


# Download and compile Python 3.12.2
RUN mkdir pyenv; \
    # Download and extract pyenv
    wget -qO- https://github.com/pyenv/pyenv/archive/refs/heads/master.tar.gz | tar xzv -C pyenv --strip-components=1; \
    # Move pyenv to the specified directory
    mv pyenv $PREFIX/pyenv; \
    # Set up pyenv in the bash environment
    echo 'export PYENV_ROOT="$PREFIX/pyenv"' >> ~/.bashrc; \
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc; \
    echo 'eval "$(pyenv init --path)"' >> ~/.bashrc; \
    . ~/.bashrc; \
    # Configure and install Python with OpenSSL support
    CPPFLAGS="-I$PREFIX/ssl/include" \
    LDFLAGS="-L$PREFIX/ssl/lib64" \
    CONFIGURE_OPTS="--with-openssl=/$PREFIX/ssl --enable-optimizations" \
    pyenv install -v 3.12.2; \
    # Set the installed Python version as the global default
    pyenv global 3.12.2;


# Download and compile CMake (dependency for GDAL)
RUN yum remove cmake -y; \
    mkdir cmake; \
    # Download and extract CMake
    wget -qO- https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz \
        | tar xvz -C cmake --strip-components=1; \
    cd cmake; \
    # Set OpenSSL root directory and bootstrap CMake
    export OPENSSL_ROOT_DIR=$PREFIX/ssl; \
    ./bootstrap; \
    # Compile and install CMake
    make -j ${NPROC}; \
    make install; \
    # Return to the previous directory and clean up
    cd ../; rm -rf cmake;


# Download and compile SQLite (dependency for proj4)
RUN mkdir sqlite3; \
    wget -qO- https://www.sqlite.org/2024/sqlite-autoconf-${SQLITE_VERSION}.tar.gz \
        | tar xvz -C sqlite3 --strip-components=1; \
    cd sqlite3; \
    ./configure --prefix=$PREFIX; \
    make -j ${NPROC} install; \
    cd ../; rm -rf sqlite3;


# Download and compile nghttp2 (dependency for curl)
RUN mkdir nghttp2; \
    wget -qO- https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz \
        | tar xzv -C nghttp2 --strip-components=1; \
    cd nghttp2;\
    ./configure  --prefix=$PREFIX; \
    make -j ${NPROC} install; \
    cd ../; rm -rf nghttp2;


# Download and compile Curl (recommended for Proj4)
RUN mkdir curl; \
    # Download and extract Curl
    wget -qO- https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz | tar xvz -C curl --strip-components=1; \
    cd curl; \
    # Configure and compile Curl
    ./configure --prefix=$PREFIX --disable-manual --disable-cookies --with-nghttp2=$PREFIX/lib --with-openssl=$PREFIX/ssl; \
    make -j ${NPROC}; \
    make install; \
    # Return to the previous directory and clean up
    cd ../; rm -rf curl;


# Download and compile libtiff (recommended for Proj4)
RUN mkdir libtiff; \
    # Download and extract libtiff
    wget -qO- https://download.osgeo.org/libtiff/tiff-$TIFF_VERSION.tar.gz \
        | tar xzv -C libtiff --strip-components=1; \
    cd libtiff; \
    # Configure and compile libtiff
    ./configure --prefix=$PREFIX; \
    make -j ${NPROC} install; \
    # Return to the previous directory and clean up
    cd ..; rm -rf libtiff;


# Download and compile PROJ (dependency for GDAL)
RUN mkdir proj; \
    # Download and extract PROJ
    wget -qO- http://download.osgeo.org/proj/proj-$PROJ_VERSION.tar.gz | tar xvz -C proj --strip-components=1; \
    cd proj; \
    mkdir build; \
    cd build; \
    # Configure PROJ with CMake
    cmake \
        -DEXE_SQLITE3=$PREFIX/bin/sqlite3 \
        -DTIFF_INCLUDE_DIR=$PREFIX/include \
        -DTIFF_LIBRARY_RELEASE=$PREFIX/lib/libtiff.so \
        -DCURL_INCLUDE_DIR=$PREFIX/include/curl \
        -DCURL_LIBRARY=$PREFIX/lib/libcurl.so \
        ..; \
    # Build and install PROJ
    cmake --build . --target install; \
    # Return to the previous directory and clean up
    cd ../..; rm -rf proj;


# Download and compile GEOS (recommended for GDAL)
RUN mkdir geos; \
    # Download and extract GEOS
    wget -qO- http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 \
       | tar xj -C geos --strip-components=1; \
    cd geos; \
    mkdir build; \
    cd build; \
    # Configure GEOS with CMake
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        ..; \
    # Build and install GEOS
    make -j ${NPROC} install; \
    # Return to the previous directory and clean up
    cd ../..; rm -rf geos;


# Download and compile PostgreSQL (recommended for GDAL)
RUN mkdir postgresql; \
    # Download and extract PostgreSQL
    wget -qO- https://ftp.postgresql.org/pub/source/v15.5/postgresql-15.5.tar.gz \
       | tar xzv -C postgresql --strip-components=1; \
    cd postgresql; \
    # Configure and compile PostgreSQL with OpenSSL support
    CPPFLAGS="-I$PREFIX/ssl/include" \
    LDFLAGS="-L$PREFIX/ssl/lib64" \
    ./configure --prefix=$PREFIX --with-openssl --without-server; \
    make -j ${NPROC} install; \
    # Return to the previous directory and clean up
    cd ../..; rm -rf postgresql;


# Download and compile GDAL
RUN mkdir gdal; \
    # Download and extract GDAL
    wget -qO- http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz \
        | tar xzv -C gdal --strip-components=1; \
    cd gdal; \
    mkdir build; \
    cd build; \
    # Configure GDAL with CMake
    cmake \
        -DBUILD_PYTHON_BINDINGS=OFF \
        -DPROJ_LIBRARY=$PREFIX/libproj.so \
        -DPROJ_INCLUDE_DIR=$PREFIX/include \
        -DGDAL_USE_POSTGRESQL=ON \
        -DPostgreSQL_LIBRARY_RELEASE=$PREFIX/lib/libpq.so \
        -DPostgreSQL_INCLUDE_DIR=$PREFIX/include \
        -DGDAL_USE_GEOS=ON \
        -DGEOS_LIBRARY=$PREFIX/lib64/libgeos.so \
        -DGEOS_INCLUDE_DIR=$PREFIX/include \
        -DCFLAGS="-O2 -Os" \
        -DCXXFLAGS="-O2 -Os" \
        -DLDFLAGS="-Wl,-rpath,'\$\$ORIGIN'" \
        -DCMAKE_BUILD_TYPE=Release \
        ..; \
    # Build and install GDAL
    cmake --build . --target install; \
    # Return to the previous directory and clean up
    cd ../..;  rm -rf gdal;


# Set the working directory
WORKDIR /home/gdalambda

# Copy the requirements file
COPY requirements.txt ./

# Install Python dependencies
RUN export PYENV_ROOT="/usr/local/pyenv" && \
    export PATH="$PYENV_ROOT/bin:$PATH" && \
    eval "$(pyenv init --path)" && \
    pip3 install -r requirements.txt ;

# Copy the package script
COPY bin/* /usr/local/bin/

RUN chmod +x /usr/local/bin/package.sh
