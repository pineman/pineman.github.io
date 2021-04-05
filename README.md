# TODO
* use a framework like next.js, gatsby, neutrino, nwb

using a bind mount for db scripts: because the db image's default entrypoint does not re-run the init scripts if `$PGDATA/PG_VERSION` exists, and `docker-compose up` preserves mounted volumes even if the image is changed, you must do this to test new files:
```sh
docker stop -t 0 homepage_db_1 && docker rm homepage_db_1
```
