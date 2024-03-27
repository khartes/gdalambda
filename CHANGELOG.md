# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

# Changelog

## [1.0.0] - 2024-03-27

### Added
- Dockerfile for building a GDALambda environment.
- Initial release of the Dockerfile.
- Support for compiling and installing:
  - OpenSSL 3.2.1
  - Python 3.12.2
  - CMake 3.27.1
  - SQLite 3.45.2
  - nghttp2 1.60.0
  - Curl 8.6.0
  - libtiff 4.6.0
  - PROJ 9.0.1
  - GEOS 3.9.5
  - PostgreSQL 15.5
  - GDAL 3.8.4
- Python packages installed:
  - numpy (version specified in `requirements.txt`)
  - GDAL 3.8.4
  - rasterio 1.3.9
  - shapely 2.0.3
  - pyproj 3.6.1

### Changed
- Updated maintainer and author labels.

### Fixed
- Corrected missing semicolon in the cleanup command for OpenSSL compilation.
