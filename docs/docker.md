# Docker

## Ubuntu 16.04 Installation

Clone this repository

```
cd /opt
git clone git@bitbucket.org:mr-php/shinken.git
cd shinken/
```

Install docker and docker-compose

```
sudo wget -qO- https://goo.gl/hukjGs | sh
```

Start the docker containers

```
sudo docker-compose up -d
```