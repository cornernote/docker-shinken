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
docker tag ad6839608d54 cornernote/shinken:latest
docker tag ad6839608d54 cornernote/shinken:2.4.3-nrpe-2.15
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
