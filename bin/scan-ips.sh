#!/bin/bash

heroku logs --app steem-ganymede --num 500000 | grep "Started GET" | cut -f 15 -d ' ' | sort | uniq
heroku logs --app golos-ganymede --num 500000 | grep "Started GET" | cut -f 15 -d ' ' | sort | uniq
