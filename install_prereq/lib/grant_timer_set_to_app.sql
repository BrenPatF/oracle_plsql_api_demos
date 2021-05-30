DEFINE app=&1
/***************************************************************************************************
Name: grant_timer_set_to_app.sql       Author: Brendan Furey                       Date: 08-Jun-2019

Grants privileges on Timer_Set components from lib to app schema (passed as parameter).

This module facilitates code timing for instrumentation and other purposes, with very small 
footprint in both code and resource usage.

	  GitHub: https://github.com/BrenPatF/timer_set_oracle

Pre-requisite: Installation of the oracle_plsql_utils module:

    GitHub: https://github.com/BrenPatF/oracle_plsql_utils

There are two install scripts, of which the second is optional: 
- install_timer_set.sql:    base code; requires base install of oracle_plsql_utils
- install_timer_set_tt.sql: unit test code; requires unit test install section of oracle_plsql_utils

The lib schema refers to the schema in which oracle_plsql_utils was installed
====================================================================================================
|  Script                      |  Notes                                                            |
|==================================================================================================|
|  install_timer_set.sql       |  Creates base components, including Timer_Set package, in lib     |
|                              |  schema                                                           |
|------------------------------|-------------------------------------------------------------------|
|  install_timer_set_tt.sql    |  Creates unit test components that require a minimum Oracle       |
|                              |  database version of 12.2 in lib schema                           |
|------------------------------|-------------------------------------------------------------------|
| *grant_timer_set_to_app.sql* |  Grants privileges on Timer_Set components from lib to app schema |
|------------------------------|-------------------------------------------------------------------|
|  c_timer_set_syns.sql        |  Creates synonyms for Timer_Set components in app schema to lib   |
|                              |  schema                                                           |
====================================================================================================

This file grants privileges on Timer_Set components from lib to app schema.

Grants applied:

    Privilege           Object                   Object Type
    ==================  =======================  ===================================================
    Execute             Timer_Set                Package

***************************************************************************************************/
PROMPT Granting Timer_Set components to &app...
GRANT EXECUTE ON Timer_Set TO &app
/