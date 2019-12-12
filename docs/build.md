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
docker tag e1313bf3693e cornernote/shinken:2.4.3-nrpe-2.15
docker tag e1313bf3693e cornernote/shinken:latest
```

Push to hub.docker.com:

```
docker login
docker push cornernote/shinken:2.4.3-nrpe-2.15
docker push cornernote/shinken:latest
```

## Shell into Image

```
docker-compose run --rm shinken bash
```
