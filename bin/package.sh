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
PYPATH=/usr/local/pyenv/versions/$PYVERSION/lib/python${PYVER}/site-packages/

EXCLUDE_DIRS="boto3* botocore* pip* docutils* setuptools* wheel* coverage* testfixtures* mock* *.egg-info *.dist-info __pycache__ test tests .pyi *.pyc easy_install.py"

# Loop para excluir cada padrão
for pattern in $EXCLUDE_DIRS; do
    find "$PYPATH" -name "$pattern" -exec rm -rf {} \;
done

# Copy all Python packages except numpy and numpy.libs
mkdir -p $DEPLOY_DIR/python
cp -a $PYPATH/* $DEPLOY_DIR/python/
rm -rf $DEPLOY_DIR/python/numpy*
rm -rf $DEPLOY_DIR/python/numpy.libs*


# zip up deploy package
cd $DEPLOY_DIR
zip --symlinks -ruq ../gdalambda.zip ./lib ./share ./bin

# Zip up all Python packages except numpy and numpy.libs
zip --symlinks -ruq ../gdalambda-python.zip ./python

# Create a separate zip file for numpy and numpy.libs
rm -rf python/*
cp -a $PYPATH/numpy* ./python/
zip --symlinks -ruq ../numpy.zip ./python

# Clean up
cd ..
rm -rf $DEPLOY_DIR
