# docker-genieacs-gui
Run GenieACS frontend in a docker container

## Container Layout
  * running Alpine-3.5
  * default installation directory is `/opt/genieacs-gui`
  * moved and symlinked config files to `/etc/genieacs-gui/conf.d`
  * moved and symlinked Rails environment files to `/etc/genieacs-gui/env.d`

## Environment Variables
  * `GENIEACS_API_HOST` (default: localhost)
  * `GENIEACS_API_PORT` (default: 7557)
  * `RAILS_ENV` (default: development)
  * `SECRET_KEY_BASE` (mandatory for production mode)

## Usage

Build your own local docker image based on this repo:
```
git clone https://github.com/covin/docker-genieacs-gui
cd docker-genieacs-gui
docker build -t genieacs-gui:edge .
```

Start a new volatile container using default sample configuration files:
```
docker run -it --rm -p 3000:3000 -e GENIEACS_API_HOST=<fqdn.or.ip.addr> genieacs-gui:edge
```

If you want to customize the configuration files it is advisable to put them on persistent storage first, e.g.:
```
P=/tmp/local/config/path
mkdir -p "$P"
docker run -d --name cfg_export -v "$P:/tmp/export" genieacs-gui:edge
docker exec --user $(id -u) cfg_export cp -r /etc/genieacs-gui/conf.d/. /tmp/export
docker stop cfg_export
docker rm -v cfg_export
```
Modify as you need and finally
```
docker run -it --rm -v "$P:/etc/genieacs-gui/conf.d" -e GENIEACS_API_HOST=<fqdn.or.ip.addr> genieacs-gui:edge
```

## Limitations & TODOs 
* Static entrypoint (bin/rails s -b 0.0.0.0) prevents alternative startup commands. Instead do `docker exec -it <CONTAINER> /bin/ash` on a running container.
* setting RAILS_ENV on container creation should trigger `rails db:migrate` before server start
* create random SECRET_KEY_BASE on demand

