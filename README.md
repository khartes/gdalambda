# Gdalambda: GDAL AWS Lambda Layer

The Gdalambda project offers a Dockerfile and related resources for building a custom environment with common geospatial libraries, including GDAL, Proj, Postgres/PostGIS, and GEOS, as well as providing a separate layer for the NumPy library. Inspired by the [GeoLambda project](https://github.com/developmentseed/geolambda) , this repository updates the Python version to 3.12.2 and is based on the Amazon Linux image. Please note that while this project provides the necessary tools and configurations, users are responsible for creating their own Docker images and AWS Lambda Layers as needed for their specific use cases.

## Usage

Although Gdalambda was initially intended for AWS Lambda, it is also useful as a base geospatial Docker image. For detailed information on what is included in each image, see the Dockerfile for that version. A summary of the versions is provided here:

| Gdalambda | GDAL  | Python | Notes                 |
| --------- | ----- | ------ | --------------------- |
| 1.0.0     | 3.8.4 | 3.12.2 | Includes Postgres/Postgis support and distributes NumPy separately |

### Environment Variables

When using Gdalambda, some environment variables need to be set. These variables are set in the Docker image, but if using the Lambda Layer, they will need to be set:

- GDAL_DATA=/opt/share/gdal
- PROJ_LIB=/opt/share/proj 

### Compiling and Creating Layers

To compile the libraries and create the Lambda layers, follow these steps:

```bash
cd gdalambda

VERSION=$(cat VERSION)

docker build . -t khartes/gdalambda:${VERSION}

docker run --rm -v $PWD:/home/gdalambda -it khartes/gdalambda:${VERSION} package.sh

aws lambda publish-layer-version --layer-name gdalambda --license-info "MIT" --description "Native geospatial libaries for all runtimes" --zip-file fileb://gdalambda.zip --region us-east-1 --profile {my_profile}

aws lambda publish-layer-version --layer-name numpy --description "Numpy for python3.12" --zip-file fileb://numpy.zip --region us-east-1 --compatible-runtimes python3.12 --compatible-architectures "x86_64" --profile {my_profile} 

aws lambda publish-layer-version --layer-name gdalambda-python --license-info "MIT" --description "Native geospatial libaries for python3.12" --zip-file fileb://gdalambda-python.zip --region us-east-1 --compatible-runtimes python3.12 --compatible-architectures "x86_64" --profile {my_profile} 
```

Replace {my_profile} with your AWS profile name.