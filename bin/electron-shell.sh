#!/bin/bash

bundle install
rake assets:precompile
export SECRET_KEY_BASE=`rake secret`
export RAILS_SERVE_STATIC_FILES=true
npm install
npm start
