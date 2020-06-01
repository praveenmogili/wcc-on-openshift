#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
import os, sys
import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

selectTemplate(os.environ['DOMAIN_TEMPLATE'])
loadTemplates()

# Selects following templates:

# - Basic WebLogic Server Domain:12.2.1.3.0
# - WebLogic Coherence Cluster Extension:12.2.1.3.0
# - Oracle JRF:12.2.1.3.0
# - Oracle Universal Content Management - Content Server:12.2.1.3.0
# - Oracle Enterprise Manager:12.2.1.3.0

cd('/Security/base_domain/User/weblogic')
set('Name', os.environ['ADMIN_USERNAME'])
set('Password', os.environ['ADMIN_PASSWORD'])
#cmo.setPassword('<WL_PASSWORD>')

cd('/Server/AdminServer')
set('Name', 'AdminServer')
set('ListenPort', 7001)
#set('ListenAddress', os.environ['IP_ADDRESS'])

cd('/')
set('Name', os.environ['DOMAIN_NAME'])

print 'Configuring the Service Table DataSource...'

cd('/JDBCSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JDBCDriverParams/NO_NAME_0')
set('DriverName', 'oracle.jdbc.OracleDriver')
set('PasswordEncrypted', os.environ['DB_SCHEMA_PASSWORD'])
set('URL', 'jdbc:oracle:thin:@//' + os.environ['DB_HOST'] + ':' + os.environ['DB_PORT'] + '/' + os.environ['DB_SERVICE'])

cd('Properties/NO_NAME_0/Property/user')
set('Value', os.environ['RCU_PREFIX'] + '_STB')

print 'Getting Database Defaults...'
getDatabaseDefaults()

# Write domain
setOption('OverwriteDomain', 'true')
writeDomain(os.environ['DOMAIN_HOME'])

# Close template
closeTemplate()

# End
exit()
