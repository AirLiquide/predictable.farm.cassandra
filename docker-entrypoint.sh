#!/bin/bash
set -e

{
	LOCKFILE=/var/tmp/lock.txt
	if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    	echo "already running"
    	exit
	fi
	# make sure the lockfile is removed when we exit and then claim it
	trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
	echo $$ > ${LOCKFILE}


	{
	  while ! echo -n > /dev/tcp/localhost/9042; do
	    sleep 10
	  done
	} 2>/dev/null
	echo "Initializing Cassandra database"
	cqlsh -e "CREATE KEYSPACE PredictableFarm  WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 }"
	cqlsh -k predictablefarm -e"CREATE TABLE sensorlog (device_id varchar,sensor_type varchar,sensor_value varchar, created_at timestamp, PRIMARY KEY ((device_id, sensor_type),  created_at))"
	cqlsh -k predictablefarm -e "CREATE TABLE relaystate (device_id varchar,sensor_type varchar,sensor_value int,last_update timestamp, PRIMARY KEY ((device_id, sensor_type)))"
	echo "Cassandra database initialized"
	rm -f ${LOCKFILE}
}&
# first arg is `-f` or `--some-option`
if [ "${1:0:1}" = '-' ]; then
	set -- cassandra -f "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'cassandra' -a "$(id -u)" = '0' ]; then
	chown -R cassandra /var/lib/cassandra /var/log/cassandra "$CASSANDRA_CONFIG"
	exec gosu cassandra "$BASH_SOURCE" "$@"
fi

if [ "$1" = 'cassandra' ]; then
	: ${CASSANDRA_RPC_ADDRESS='0.0.0.0'}

	: ${CASSANDRA_LISTEN_ADDRESS='auto'}
	if [ "$CASSANDRA_LISTEN_ADDRESS" = 'auto' ]; then
		CASSANDRA_LISTEN_ADDRESS="$(hostname --ip-address)"
	fi

	: ${CASSANDRA_BROADCAST_ADDRESS="$CASSANDRA_LISTEN_ADDRESS"}

	if [ "$CASSANDRA_BROADCAST_ADDRESS" = 'auto' ]; then
		CASSANDRA_BROADCAST_ADDRESS="$(hostname --ip-address)"
	fi
	: ${CASSANDRA_BROADCAST_RPC_ADDRESS:=$CASSANDRA_BROADCAST_ADDRESS}

	if [ -n "${CASSANDRA_NAME:+1}" ]; then
		: ${CASSANDRA_SEEDS:="cassandra"}
	fi
	: ${CASSANDRA_SEEDS:="$CASSANDRA_BROADCAST_ADDRESS"}
	
	sed -ri 's/(- seeds:).*/\1 "'"$CASSANDRA_SEEDS"'"/' "$CASSANDRA_CONFIG/cassandra.yaml"

	for yaml in \
		broadcast_address \
		broadcast_rpc_address \
		cluster_name \
		endpoint_snitch \
		listen_address \
		num_tokens \
		rpc_address \
		start_rpc \
	; do
		var="CASSANDRA_${yaml^^}"
		val="${!var}"
		if [ "$val" ]; then
			sed -ri 's/^(# )?('"$yaml"':).*/\2 '"$val"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
		fi
	done

	for rackdc in dc rack; do
		var="CASSANDRA_${rackdc^^}"
		val="${!var}"
		if [ "$val" ]; then
			sed -ri 's/^('"$rackdc"'=).*/\1 '"$val"'/' "$CASSANDRA_CONFIG/cassandra-rackdc.properties"
		fi
	done
fi

exec "$@"
