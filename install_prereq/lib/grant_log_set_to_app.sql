DEFINE app=&1
/***************************************************************************************************
Name: grant_log_set_to_app.sql          Author: Brendan Furey                       Date: 08-Jun-2019

Grants privileges on Log_Set components from lib to app schema (passed as parameter).

This is a logging framework that supports the writing of messages to log tables, along with various
optional data items that may be specified as parameters or read at runtime via system calls.

    GitHub: https://github.com/BrenPatF/log_set_oracle

Pre-requisite: Installation of the oracle_plsql_utils module:

    GitHub: https://github.com/BrenPatF/oracle_plsql_utils

There are two install scripts, of which the second is optional: 
- install_log_set.sql:    base code; requires base install of oracle_plsql_utils
- install_log_set_tt.sql: unit test code; requires unit test install section of oracle_plsql_utils

The lib schema refers to the schema in which oracle_plsql_utils was installed.
====================================================================================================
|  Script                    |  Notes                                                              |
|===================================================================================================
|  install_log_set.sql       |  Creates base components, including Log_Set package, in lib schema  |
----------------------------------------------------------------------------------------------------
|  install_log_set_tt.sql    |  Creates unit test components that require a minimum Oracle         |
|                            |  database version of 12.2 in lib schema                             |
----------------------------------------------------------------------------------------------------
| *grant_log_set_to_app.sql* |  Grants privileges on Timer_Set components from lib to app schema   |
----------------------------------------------------------------------------------------------------
|  c_log_set_syns.sql        |  Creates synonyms for Timer_Set components in app schema to lib     |
|                            |  schema                                                             |
====================================================================================================

This file grants privileges on Timer_Set components from lib to app schema.

Grants applied:

    Privilege           Object                   Object Type
    ==================  =======================  ===================================================
    Select              log_configs              Table
    Select              log_headers              Table
    Select              log_lines                Table
    Execute             Log_Config               Package
    Execute             Log_Set                  Package

***************************************************************************************************/
PROMPT Granting Timer_Set components to &app...
GRANT SELECT ON log_configs TO &app
/
GRANT SELECT ON log_headers TO &app
/
GRANT SELECT ON log_lines TO &app
/
GRANT EXECUTE ON Log_Config TO &app
/
GRANT EXECUTE ON Log_Set TO &app
/