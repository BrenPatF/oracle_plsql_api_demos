DEFINE lib=&1
/***************************************************************************************************
Name: c_log_set_syns.sql               Author: Brendan Furey                       Date: 08-Jun-2019

Creates synonyms for Log_Set components in app schema to lib schema.

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
|==================================================================================================|
|  install_log_set.sql       |  Creates base components, including Log_Set package, in lib schema  |
|----------------------------|---------------------------------------------------------------------|
|  install_log_set_tt.sql    |  Creates unit test components that require a minimum Oracle         |
|                            |  database version of 12.2 in lib schema                             |
|----------------------------|---------------------------------------------------------------------|
|  grant_log_set_to_app.sql  |  Grants privileges on Log_Set components from lib to app schema     |
|----------------------------|---------------------------------------------------------------------|
| *c_log_set_syns.sql*       |  Creates synonyms for Log_Set components in app schema to lib       |
|                            |  schema                                                             |
====================================================================================================

Creates synonyms for Log_Set components in app schema to lib schema.

Synonyms created:

    Synonym             Object Type
    ==================  ============================================================================
    log_configs         Table
    log_headers         Table
    log_lines           Table
    Log_Config          Package
    Log_Set             Package

***************************************************************************************************/
PROMPT Creating synonyms for &lib Log_Set components...
CREATE OR REPLACE SYNONYM log_configs FOR &lib..log_configs
/
CREATE OR REPLACE SYNONYM log_headers FOR &lib..log_headers
/
CREATE OR REPLACE SYNONYM log_lines FOR &lib..log_lines
/
CREATE OR REPLACE SYNONYM Log_Config FOR &lib..Log_Config
/
CREATE OR REPLACE SYNONYM Log_Set FOR &lib..Log_Set
/