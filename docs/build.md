## Building Images

Build images:

```
docker-compose build
docker-compose build --no-cache     # if files/* changes
```

List images:

```
docker images
```

Tag image:

```
docker tag b15a3465e400 cornernote/shinken:latest
docker tag b15a3465e400 cornernote/shinken:2.4.3-nrpe-2.15
```

Push to hub.docker.com:

```
docker login
docker push cornernote/shinken:latest
docker push cornernote/shinken:2.4.3-nrpe-2.15
```

## Shell into Image

```
docker-compose run --rm shinken bash
```
