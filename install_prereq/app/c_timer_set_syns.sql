DEFINE lib=&1
/***************************************************************************************************
Name: c_timer_set_syns.sql             Author: Brendan Furey                       Date: 08-Jun-2019

Creates synonyms for Timer_Set components in app schema to lib schema.

This module facilitates code timing for instrumentation and other purposes, with very small 
footprint in both code and resource usage.

	  GitHub: https://github.com/BrenPatF/timer_set_oracle

Pre-requisite: Installation of the oracle_plsql_utils module:

    GitHub: https://github.com/BrenPatF/oracle_plsql_utils

There are two install scripts, of which the second is optional: 
- install_timer_set.sql:    base code; requires base install of oracle_plsql_utils
- install_timer_set_tt.sql: unit test code; requires unit test install section of oracle_plsql_utils

The lib schema refers to the schema in which oracle_plsql_utils was installed.
====================================================================================================
|  Script                      |  Notes                                                            |
|==================================================================================================|
|  install_timer_set.sql       |  Creates base components, including Timer_Set package, in lib     |
|                              |  schema                                                           |
|------------------------------|-------------------------------------------------------------------|
|  install_timer_set_tt.sql    |  Creates unit test components that require a minimum Oracle       |
|                              |  database version of 12.2 in lib schema                           |
|------------------------------|-------------------------------------------------------------------|
| grant_timer_set_to_app.sql   |  Grants privileges on Timer_Set components from lib to app schema |
|------------------------------|-------------------------------------------------------------------|
| *c_timer_set_syns.sql*       |  Creates synonyms for Timer_Set components in app schema to lib   |
|                              |  schema                                                           |
====================================================================================================

Creates synonyms for Timer_Set components in app schema to lib schema.

Synonyms created:

    Synonym             Object Type
    ==================  ============================================================================
    Timer_Set           Package

***************************************************************************************************/
PROMPT Creating synonyms for &lib Timer_Set components...
CREATE OR REPLACE SYNONYM Timer_Set FOR &lib..Timer_Set
/