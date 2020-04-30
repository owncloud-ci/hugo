# hugo

[![Build Status](https://drone.owncloud.com/api/badges/owncloud-ci/hugo/status.svg)](https://drone.owncloud.com/owncloud-ci/hugo/)
[![Docker Hub](https://img.shields.io/badge/docker-latest-blue.svg?logo=docker&logoColor=white)](https://hub.docker.com/r/owncloudci/hugo)


## Build

```Shell
docker build --build-arg BUILD_VERSION=0.69.2 -f Dockerfile -t hugo:latest .
```

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](https://github.com/owncloud-ci/hugo/blob/master/LICENSE) file for details.
