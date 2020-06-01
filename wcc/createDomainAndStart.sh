#!/bin/bash
#
# Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

# Exit immediately if any command exits non-zero
set -eo pipefail

# Die function
die() { printf "ERROR: %s" "$1" >&2; exit 1; }

########### SIGINT handler ############
function stopServer() {
   echo "Stop or kill signal received, Stopping...."

   # TODO Stop scripts should go here!
   exit
}

#######Random Password Generation########
function randomPwd() {
  while true; do
    s=$(tr -cd '[:alnum:]' </dev/urandom | head -c8)
    if [[ ${#s} -ge 8 && $s == *[A-Z]* && $s == *[a-z]* && $s == [A-Za-z]*[0-9]* ]]; then
      break
    else
      echo "Password does not Match the criteria, re-generating..." >&2
    fi
  done
  echo "${s}"
}

# Set signal handler
trap stopServer SIGINT SIGTERM SIGKILL

# Check for required environment variables
for required in \
  DB_USERNAME DB_PASSWORD DB_HOST DB_PORT DB_SERVICE RCU_PREFIX MANAGED_SERVER
do [[ ${!required} ]] || die "Please set ${required}!"
done

# Wait for database listener
wait-for -h $DB_HOST -p $DB_PORT -t $WAIT_TIMEOUT

# Sleep for a bit to let database register with listener in case of new database
sleep 10

# Set DB connection string
export CONNECTION_STRING="$DB_HOST:$DB_PORT/$DB_SERVICE"

# Set domain home
export DOMAIN_HOME=${DOMAIN_HOME:-"$DOMAIN_ROOT/$DOMAIN_NAME"}

# Get IP address
export IP_ADDRESS=$(hostname -I | cut -d' ' -f1)

# Check if domain exists
if [[ ! -d $DOMAIN_HOME ]]; then

  # Run RCU?
  if ((RUN_RCU)) && [[ ! -f ~/.rcu_done ]]; then

    # Auto generate schema password
    if [[ ! $DB_SCHEMA_PASSWORD ]]; then
      # Auto generate Oracle Database Schema password
      export DB_SCHEMA_PASSWORD=$(randomPwd)
      printf 'Database Schema password Auto Generated :\n\n ---> Database schema password: %s\n\n' "$DB_SCHEMA_PASSWORD"
    fi

    # Execute RCU
    printf '%s\n' "$DB_PASSWORD" "$DB_SCHEMA_PASSWORD" |
      $ORACLE_HOME/oracle_common/bin/rcu \
        -silent -createRepository -connectString $CONNECTION_STRING \
        -dbUser $DB_USERNAME -dbRole sysdba -useSamePasswordForAllSchemaUsers true -schemaPrefix $RCU_PREFIX \
        -component MDS -component STB -component WLS -component CONTENT -component CAPTURE \
        -component OPSS -component IAU -component IAU_APPEND -component IAU_VIEWER

    # Mark RCU as done
    touch ~/.rcu_done
  fi

  # Schema password set? (If RCU is not run, for example)
  [[ $DB_SCHEMA_PASSWORD ]] || die "Please set DB_SCHEMA_PASSWORD!"

  # Create domain
  wlst.sh -skipWLSModuleScanning $CONTAINER_SCRIPT_DIR/createDomain.py

fi

# Navigate to domain home
cd $DOMAIN_HOME

# Set up managed server security
if [[ ! -d servers/$MANAGED_SERVER/security ]]; then
  # Create security directory
  mkdir -pv servers/$MANAGED_SERVER/security

  # Create symbolic link from admin server's boot.properties file to managed server
  if [[ ! -f servers/$MANAGED_SERVER/security/boot.properties ]]; then
    ln -srv servers/AdminServer/security/boot.properties servers/$MANAGED_SERVER/security/
  fi
fi

# Start Admin Server
bin/startWebLogic.sh &

# Wait for admin server
wait-for -h localhost -p 7001 -t $WAIT_TIMEOUT

# Sleep for a bit
sleep 10

# Start Managed Server
bin/startManagedWebLogic.sh $MANAGED_SERVER t3://localhost:7001

# Wait for ever, until signal received
while true; do tail -f /dev/null; wait $!; done
