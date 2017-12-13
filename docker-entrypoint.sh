#!/bin/bash
set -e

{
	LOCKFILE=/var/tmp/lock.txt
	#if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
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


	if [ ! -d "/var/lib/cassandra/data/predictablefarm" ]; then
		echo "Initializing Cassandra database"
		cqlsh -e "DROP KEYSPACE IF EXISTS PredictableFarm"
		cqlsh -e "CREATE KEYSPACE PredictableFarm  WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 }"
		cqlsh -k predictablefarm -e "CREATE TABLE sensorlog (device_id varchar,sensor_type varchar,sensor_value varchar, created_at timestamp, PRIMARY KEY ((device_id, sensor_type),  created_at))"
		cqlsh -k predictablefarm -e "CREATE TABLE relaystate (device_id varchar,sensor_type varchar,sensor_value int,last_update timestamp, PRIMARY KEY ((device_id, sensor_type)))"
		cqlsh -k predictablefarm -e "CREATE TABLE zone (id_zone int PRIMARY KEY, name varchar,location varchar,location_gps varchar, dashboards text)"
		cqlsh -k predictablefarm -e "CREATE TABLE probe (id_probe int PRIMARY KEY,id_zone int,name varchar,uuid varchar)"
		cqlsh -k predictablefarm -e "CREATE TABLE reading (id_sensor int PRIMARY KEY,value varchar,time timestamp)"
		cqlsh -k predictablefarm -e "CREATE TABLE sensor (id_sensor int PRIMARY KEY,id_probe int,type varchar,last_value varchar,last_time timestamp,sort_order int)"

  	# Control will enter here if $DIRECTORY doesn't exist.
		cqlsh -k predictablefarm -e "INSERT INTO probe (id_probe, id_zone, name, uuid) VALUES (1,1,'Arduino','ed6f47ad4fba493085d4f9fdeb3f6a75')"
		cqlsh -k predictablefarm -e "INSERT INTO probe (id_probe, id_zone, name, uuid) VALUES (2,0,'BT proto','ebf22bd24ec34ac2bc2618e21f71f753')"
		cqlsh -k predictablefarm -e "INSERT INTO probe (id_probe, id_zone, name, uuid) VALUES (173,0,'Ethernet proto','3735928559')"
		cqlsh -k predictablefarm -e "INSERT INTO reading (id_sensor,value,time ) VALUES (1,'20.5','2016-11-23 10:06:39')"

		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (1,1,'temperature','23.7','2016-11-28 17:37:03',NULL)"
		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (2,1,'pressure','102118','2016-11-28 17:38:32',NULL)"
		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (3,1,'lux','343','2016-11-28 17:38:32',NULL)"
		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (4,2,'sunuvlight','4','2017-02-06 16:49:25',1)"
		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (5,2,'lux','274','2017-02-06 16:49:37',2)"
		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (6,2,'sunvisiblelight','264','2017-02-06 16:49:31',3)"
		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (7,2,'sunirlight','269','2017-02-06 16:49:37',0)"
		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (8,2,'humidity','38.5','2017-02-06 16:49:01',5)"
		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (9,2,'pressure','101379','2017-02-06 16:49:39',6)"
		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (10,3,'temperature','20.3','2017-02-06 16:49:33',4)"



		cqlsh -k predictablefarm -e "INSERT INTO zone (id_zone, name, location, location_gps, dashboards) VALUES (0, 'Zone par defaut',NULL,NULL,\$\$[{'name':'Heat / Moisture','blocks':[{'type':'sensors','name':'Heat / Moisture','sensors':[{'id_sensor':'8','id_probe':'2','type':'humidity','last_value':'42.7','last_time':'2017-02-02 15:28:13','sort_order':5,'probe_uuid':'ebf22bd24ec34ac2bc2618e21f71f753','probe_name':'BT proto','id_zone':'0','label':'Humidite','style':'percent','class':'air','color':'red','sensor_index':0},{'id_sensor':'10','id_probe':'2','type':'temperature','last_value':'21.1','last_time':'2017-02-02 15:28:06','sort_order':4,'probe_uuid':'ebf22bd24ec34ac2bc2618e21f71f753','probe_name':'BT proto','id_zone':'0','label':'Temperature','style':'celcius-degrees','class':'air','color':'red','sensor_index':1},{'id_sensor':'4','id_probe':'2','type':'sunuvlight','last_value':'5','last_time':'2017-02-02 15:28:20','sort_order':1,'probe_uuid':'ebf22bd24ec34ac2bc2618e21f71f753','probe_name':'BT proto','id_zone':'0','label':'UV (Ultraviolet)','style':'','class':'light','color':'red','sensor_index':2}],'displayChart':true,'displaySensor':true,'id_zone':'0','dashboard_index':0,'block_index':0,'sensor_ids':'8,10,4'}]},{'name':'Pressure / Light','blocks':[{'type':'sensors','name':'Pressure / Light','sensors':[{'id_sensor':'9','id_probe':'2','type':'pressure','last_value':'99657','last_time':'2017-02-02 15:28:20','sort_order':6,'probe_uuid':'ebf22bd24ec34ac2bc2618e21f71f753','probe_name':'BT proto','id_zone':'0','label':'Pression Atmospherique','style':'pascal-to-hectopascal','class':'air','color':'red','sensor_index':0},{'id_sensor':'5','id_probe':'2','type':'lux','last_value':'438','last_time':'2017-02-02 15:28:14','sort_order':2,'probe_uuid':'ebf22bd24ec34ac2bc2618e21f71f753','probe_name':'BT proto','id_zone':'0','label':'Luminosite','style':'lux','class':'light','color':'red','sensor_index':1},{'id_sensor':'10','id_probe':'2','type':'temperature','last_value':'21.1','last_time':'2017-02-02 15:28:06','sort_order':4,'probe_uuid':'ebf22bd24ec34ac2bc2618e21f71f753','probe_name':'BT proto','id_zone':'0','label':'Temperature','style':'celcius-degrees','class':'air','color':'red','sensor_index':2}],'displayChart':true,'displaySensor':true,'id_zone':'0','dashboard_index':1,'block_index':0,'sensor_ids':'9,5,10'}]}]\$\$)"

		cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (11, 0, 'light', '42', toTimestamp(now()),0)"

		echo "Cassandra database initialized"

		#cqlsh:predictablefarm> INSERT INTO probe (id_probe, id_zone, name, uuid) VALUES (0,0,'Device 1','1') ;
		#cqlsh:predictablefarm> INSERT INTO probe (id_probe, id_zone, name, uuid) VALUES (1,0,'Device 2','2') ;
		# cqlsh -k predictablefarm -e "INSERT INTO zone (id_zone, name, location, location_gps, dashboards) VALUES (0, 'Zone par defaut 2',NULL,NULL,\$\$[{\"name\":\"Heat2 / Moisture\",\"blocks\":[{\"type\":\"sensors\",\"name\":\"Heat2 / Moisture\",\"sensors\":[{\"id_sensor\":\"8\",\"id_probe\":\"2\",\"type\":\"humidity\",\"last_value\":\"42.7\",\"last_time\":\"2017-02-02 15:28:13\",\"sort_order\":5,\"probe_uuid\":\"ebf22bd24ec34ac2bc2618e21f71f753\",\"probe_name\":\"BT proto\",\"id_zone\":\"0\",\"label\":\"Humidite\",\"style\":\"percent\",\"class\":\"air\",\"color\":\"red\",\"sensor_index\":0},{\"id_sensor\":\"10\",\"id_probe\":\"2\",\"type\":\"temperature\",\"last_value\":\"21.1\",\"last_time\":\"2017-02-02 15:28:06\",\"sort_order\":4,\"probe_uuid\":\"ebf22bd24ec34ac2bc2618e21f71f753\",\"probe_name\":\"BT proto\",\"id_zone\":\"0\",\"label\":\"Temperature\",\"style\":\"celcius-degrees\",\"class\":\"air\",\"color\":\"red\",\"sensor_index\":1},{\"id_sensor\":\"4\",\"id_probe\":\"2\",\"type\":\"sunuvlight\",\"last_value\":\"5\",\"last_time\":\"2017-02-02 15:28:20\",\"sort_order\":1,\"probe_uuid\":\"ebf22bd24ec34ac2bc2618e21f71f753\",\"probe_name\":\"BT proto\",\"id_zone\":\"0\",\"label\":\"UV (Ultraviolet)\",\"style\":\"\",\"class\":\"light\",\"color\":\"red\",\"sensor_index\":2}],\"displayChart\":true,\"displaySensor\":true,\"id_zone\":\"0\",\"dashboard_index\":0,\"block_index\":0,\"sensor_ids\":\"8,10,4\"}]},{\"name\":\"Pressure2 / Light\",\"blocks\":[{\"type\":\"sensors\",\"name\":\"Pressure / Light\",\"sensors\":[{\"id_sensor\":\"9\",\"id_probe\":\"2\",\"type\":\"pressure\",\"last_value\":\"99657\",\"last_time\":\"2017-02-02 15:28:20\",\"sort_order\":6,\"probe_uuid\":\"ebf22bd24ec34ac2bc2618e21f71f753\",\"probe_name\":\"BT proto\",\"id_zone\":\"0\",\"label\":\"Pression Atmospherique\",\"style\":\"pascal-to-hectopascal\",\"class\":\"air\",\"color\":\"red\",\"sensor_index\":0},{\"id_sensor\":\"5\",\"id_probe\":\"2\",\"type\":\"lux\",\"last_value\":\"438\",\"last_time\":\"2017-02-02 15:28:14\",\"sort_order\":2,\"probe_uuid\":\"ebf22bd24ec34ac2bc2618e21f71f753\",\"probe_name\":\"BT proto\",\"id_zone\":\"0\",\"label\":\"Luminosite\",\"style\":\"lux\",\"class\":\"light\",\"color\":\"red\",\"sensor_index\":1},{\"id_sensor\":\"10\",\"id_probe\":\"2\",\"type\":\"temperature\",\"last_value\":\"21.1\",\"last_time\":\"2017-02-02 15:28:06\",\"sort_order\":4,\"probe_uuid\":\"ebf22bd24ec34ac2bc2618e21f71f753\",\"probe_name\":\"BT proto\",\"id_zone\":\"0\",\"label\":\"Temperature\",\"style\":\"celcius-degrees\",\"class\":\"air\",\"color\":\"red\",\"sensor_index\":2}],\"displayChart\":true,\"displaySensor\":true,\"id_zone\":\"0\",\"dashboard_index\":1,\"block_index\":0,\"sensor_ids\":\"9,5,10\"}]}]\$\$)"
		#
		# cqlsh -k predictablefarm -e "INSERT INTO sensor (id_sensor, id_probe, type, last_value, last_time, sort_order) VALUES (11, 0, 'light', '42', toTimestamp(now()),0)"
		#
		# echo "Cassandra database initialized :)"
	fi

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
