#!/bin/bash
echo Creating deploy packages for GDAL
# directory used for development
export DEPLOY_DIR=lambda

# make deployment directory and add lambda handler
mkdir -p $DEPLOY_DIR/lib

# copy libs
cp -P ${PREFIX}/lib/*.so* $DEPLOY_DIR/lib/
cp -P ${PREFIX}/lib64/*.so* $DEPLOY_DIR/lib/

strip $DEPLOY_DIR/lib/* || true

#COPY GDAL Utilities
mkdir -p $DEPLOY_DIR/bin

# copy utilities
cp -P ${PREFIX}/bin/gdal* $DEPLOY_DIR/bin/
cp -P ${PREFIX}/bin/ogr* $DEPLOY_DIR/bin/

# copy GDAL_DATA files over
mkdir -p $DEPLOY_DIR/share
rsync -ax $PREFIX/share/gdal $DEPLOY_DIR/share/
rsync -ax $PREFIX/share/proj $DEPLOY_DIR/share/

# Get Python version
PYVERSION=$(cat /usr/local/pyenv/version)
MAJOR=${PYVERSION%%.*}
MINOR=${PYVERSION#*.}
PYVER=${PYVERSION%%.*}.${MINOR%%.*}
PYPATH=/usr/local/pyenv/versions/$PYVERSION/
# zip up gdalambda deploy package
cd $DEPLOY_DIR
cp -a $PYPATH/bin/* ./bin/
zip --symlinks -ruq ../gdalambda.zip ./lib ./share ./bin


# Create a separate zip file for numpy and numpy.libs
mkdir -p ./python/lib/python${PYVER}/site-packages/
cp -a $PYPATH/lib/python${PYVER}/site-packages/numpy* ./python/lib/python${PYVER}/site-packages/
zip --symlinks -ruq ../numpy.zip ./python/

# Copy all Python packages except numpy and numpy.libs
cp -a $PYPATH/lib/python${PYVER}/site-packages/* ./python/lib/python${PYVER}/site-packages/

rm -rf ./python/lib/python${PYVER}/site-packages/numpy*
rm -rf ./python/lib/python${PYVER}/site-packages/numpy.libs*

# Zip up all Python packages except numpy and numpy.libs
zip --symlinks -ruq ../gdalambda-python.zip ./python/

# Clean up
cd ..
rm -rf $DEPLOY_DIR
