FROM python:2.7-slim

MAINTAINER Azavea

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    g++ \
    git \
    gfortran \
    libatlas-base-dev \
    libblas-dev \
    libgeos-dev \
    liblapack-dev \
    libopenmpi-dev \
    libtool \
    openmpi-bin \
    python-all-dev \
    python-pip \
    wget

# Download, build, and install GDAL
RUN cd tmp && \
    wget http://download.osgeo.org/gdal/gdal-1.9.0.tar.gz && \
    tar xvfz gdal-1.9.0.tar.gz && \
    cd gdal-1.9.0 && \
    ./configure --with-python -with-geos=yes && \
    make && \
    make install

# Download, build, and install PROJ
RUN cd tmp && \
    wget http://download.osgeo.org/proj/proj-4.8.0.tar.gz && \
    wget http://download.osgeo.org/proj/proj-datumgrid-1.5.tar.gz && \
    tar xzf proj-4.8.0.tar.gz && \
    cd proj-4.8.0/nad && \
    tar xzf ../../proj-datumgrid-1.5.tar.gz && \
    cd .. && \
    ./configure && \
    make && \
    make install

# Set env vars
ENV PATH /usr/local/bin:$PATH
ENV CPATH /usr/local/include:/usr/include/gdal:$CPATH
ENV CPLUS_INCLUDE_PATH /usr/include/gdal
ENV C_INCLUDE_PATH /usr/include/gdal
ENV LIBRARY_PATH /usr/local/lib:$LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/local/lib:$LD_LIBRARY_PATH
RUN git clone https://github.com/dtarb/TauDEM.git /opt/taudem

# Clone and build taudem
# Remove the TestSuite directory because it contains large files
# that we don't need.
RUN cd /opt/taudem/src && make
ENV PATH /opt/taudem/:$PATH
RUN rm -rf /opt/taudem/TestSuite

# Clone and build RWD
RUN git clone https://github.com/WikiWatershed/rapid-watershed-delineation.git /opt/rwd && \
    cd /opt/rwd && \
    git fetch && \
    git checkout feature/requirements && \
    pip install --no-cache-dir -r requirements.txt

# Rebuild GDAL now that numpy is installed
# There are circular dependencies (we need GDAL to
# install python libraries, but we also need python
# libraries to build GDAL in the way we need it).
RUN cd tmp\gdal-1.9.0 && \
    ./configure --with-python -with-geos=yes && \
    make && \
    make install
