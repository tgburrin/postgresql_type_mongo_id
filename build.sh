#!/usr/bin/env bash

gcc -I`pg_config --includedir-server` -shared -o mongo_data.so mongo_data.c && mv mongo_data.so `pg_config --pkglibdir`
