#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: This file is used to build Oracle WebCenter Content image
#
# Pull base image from the Oracle Container Registry or Docker Store and tag the name as 'oracle/fmw-infrastructure:12.2.1.3'
# -------------------------------------------------------------
FROM container-registry.oracle.com/middleware/fmw-infrastructure:12.2.1.4
#FROM fmw-infrastructure

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
USER root

ENV ROOT_HOME=/u01
ENV	ORACLE_HOME=$ROOT_HOME/oracle
ENV	MW_HOME=$ORACLE_HOME
ENV	WL_HOME=$ORACLE_HOME/wlserver
ENV	CONTAINER_SCRIPT_DIR=$ORACLE_HOME/container-scripts 
ENV	WLS_HOME=$WL_HOME/server \
	UCM_ORACLE_HOME=$ORACLE_HOME/wccontent \
	DOMAIN_ROOT=$ORACLE_HOME/user_projects/domains \
	PATH=$PATH:$JAVA_HOME/bin:$ORACLE_HOME/oracle_common/common/bin:$CONTAINER_SCRIPT_DIR \
	CONTENT_PKG=fmw_12.2.1.4.0_wccontent_Disk1_1of1.zip \
	CONTENT_SHA1=521cfd9f33b89005bd94af51dd05a36868461b82 \
	CONTENT_JAR=fmw_12.2.1.4.0_wccontent.jar \
	ADMIN_PORT=7001 \
	WCCONTENT_PORT=16200 \
	ADMIN_SSL_PORT=9001 \
	WCCONTENT_SSL_PORT=9002 \
	LANG=en_US.UTF8 \
	LC_ALL=en_US.UTF8 \
	NLS_LANG=AMERICAN_AMERICA \
	USER_MEM_ARGS="-Djava.security.egd=file:/dev/urandom"


# Copy packages, scripts, and zip binary
# -------------------------------------------------------------
COPY --chown=oracle install.file oraInst.loc $CONTENT_PKG $ROOT_HOME/

# Install missing packages
# -------------------------------------------------------------
RUN yum install -y unzip hostname && rm -rf /var/cache/yum

#Install packages and adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# -------------------------------------------------------------
RUN mkdir -p $ORACLE_HOME/logs && chmod a+xr $ROOT_HOME

# Install as user
# -------------------------------------------------------------
USER oracle

WORKDIR $ROOT_HOME

# Install
RUN printf "%s *%s\n" $CONTENT_SHA1 $CONTENT_PKG | sha1sum -c \
 && unzip $CONTENT_PKG \
 && $JAVA_HOME/bin/java -jar $CONTENT_JAR -silent -force -novalidation -ignoreSysPrereqs \
	-responseFile $ROOT_HOME/install.file -invPtrLoc $ROOT_HOME/oraInst.loc -jreLoc $JAVA_HOME ORACLE_HOME=$ORACLE_HOME \
	&& rm -rf $CONTENT_JAR $CONTENT_PKG oraInst.loc install.file fmw_12214_readme.htm

WORKDIR $ORACLE_HOME

# Copy scripts and make them executable
USER root
COPY --chown=oracle wait-for createDomain.py createDomainAndStart.sh $CONTAINER_SCRIPT_DIR/
RUN chmod +x $CONTAINER_SCRIPT_DIR/*.sh
USER oracle

# Set defaults
ENV WAIT_TIMEOUT=1800 \
    MANAGED_SERVER=UCM_server1 \
    DOMAIN_TEMPLATE="Oracle Universal Content Management - Content Server"

# Define default command to start bash
CMD createDomainAndStart.sh

# Expose all ports
EXPOSE $ADMIN_PORT $ADMIN_SSL_PORT $WCCONTENT_PORT $WCCONTENT_SSL_PORT
#
