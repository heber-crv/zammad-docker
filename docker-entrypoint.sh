#!/bin/bash

#set -e

if [ "$1" = 'zammad' ]; then
  #service elasticsearch start
  #populate database
  #echo "Populate database"
  #bundle exec rake db:migrate
  #bundle exec rake db:seed

  #assets precompile
  #echo "assets precompile"
  #bundle exec rake assets:precompile

  #delete assets precompile cache
  #echo "deleting assets precompile cache"
  #rm -r tmp/cache

  #create searchindex
  #echo "create searchindex"
  #bundle exec rails r "Setting.set('es_url', 'http://localhost:9200')"
  #bundle exec rake searchindex:rebuild
  #apt-get clean -y && rm -rf preseed.txt /tmp/install-zammad.sh /var/lib/apt/lists/*

  echo -e "\n Starting services... \n"

  # starting services
  echo "Starting postgresql"
  #service postgresql start > /dev/null
  (service postgresql start | true)
  echo "postgresql started"
  echo "Starting elasticsearch"
  service elasticsearch start
  echo "elasticsearch started"
  echo "Starting postfix"
  service postfix start
  echo "postfix started"
  echo "Starting memcached"
  service memcached start
  echo "memcached started"
  echo "Starting nginx"
  service nginx start
  echo "nginx started"

  # wait for postgres processe coming up
  until su - postgres -c 'psql -c "select version()"' &> /dev/null; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
  done

  cd "${ZAMMAD_DIR}"

  echo -e "\n Starting Zammad... \n"
  su -c "bundle exec script/websocket-server.rb -b 0.0.0.0 start &" zammad
  su -c "bundle exec script/scheduler.rb start &" zammad

  # show url
  echo -e "\nZammad will be ready in some seconds! Visit http://localhost in your browser!"

  # start railsserver
  if [ "${RAILS_SERVER}" == "puma" ]; then
    su -c "bundle exec puma -b tcp://0.0.0.0:3000 -e ${RAILS_ENV}" zammad
  elif [ "${RAILS_SERVER}" == "unicorn" ]; then
    su -c "bundle exec unicorn -p 3000 -c config/unicorn.rb -E ${RAILS_ENV}" zammad
  fi
fi
