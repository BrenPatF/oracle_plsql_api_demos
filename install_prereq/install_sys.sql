@initspool install_sys
/***************************************************************************************************
Name: install_sys.sql                  Author: Brendan Furey                       Date: 14-May-2019

Installation script run from sys schema in the Oracle oracle_plsql_utils module. Creates lib and app
schemas, a directory input_dir, and does some grants.

This module comprises a set of generic user-defined Oracle types and a PL/SQL package of functions
and procedures of general utility.

    GitHub: https://github.com/BrenPatF/oracle_plsql_utils

There are install scripts for sys, lib and app schemas. However the base code alone can be installed
via install_utils.sql in an existing schema without executing the other scripts.

If the unit test code is to be installed, trapit_oracle_tester module must be installed after the 
base install: https://github.com/BrenPatF/trapit_oracle_tester.
====================================================================================================
|  Script                  |  Notes                                                                |
|===================================================================================================
| *install_sys.sql*        |  sys script creates: lib and app schemas; input_dir directory; grants |
----------------------------------------------------------------------------------------------------
|  install_utils.sql       |  Creates base components, including Utils package, in lib schema      |
----------------------------------------------------------------------------------------------------
|  install_utils_tt.sql    |  Creates unit test components that require a minimum Oracle database  |
|                          |  version of 12.2 in lib schema                                        |
----------------------------------------------------------------------------------------------------
|  grant_utils_to_app.sql  |  Grants privileges on Utils components from lib to app schema         |
----------------------------------------------------------------------------------------------------
|  install_col_group.sql   |  Creates components for the Col_Group example in app schema           |
----------------------------------------------------------------------------------------------------
|  c_utils_syns.sql        |  Creates synonyms for Utils components in app schema to lib schema    |
====================================================================================================

This file has the install script run from the sys schema.

Components created:

    Users               Description
    ==================  ============================================================================
    lib    		        Schema where the base and unit test code is installed
    app                 Schema where the example code is installed

    Directory           Description
    ==================  ============================================================================
    input_dir           Points to OS folder where example csv file and JSON files are placed

    Grants to lib, app  Description
    ==================  ============================================================================
    See c_user.sql      Various privileges

    Grants to lib only  Description
    ==================  ============================================================================
    Create Any Context  Context used to signify unit test mode
    DBMS_Lock           Sys package used by unit test code

    Grants to app only  Description
    ==================  ============================================================================
    Create Synonym      To allow creation of private synonyms to lib components

***************************************************************************************************/
DEFINE LIB_USER=lib
DEFINE APP_USER=app

PROMPT Create directory input_dir
CREATE OR REPLACE DIRECTORY input_dir AS 'C:\input'
/
PROMPT Create &LIB_USER
@c_user &LIB_USER
PROMPT Grant Execute DBMS_Lock to &LIB_USER
GRANT EXECUTE ON DBMS_Lock TO &LIB_USER
/
PROMPT Grant Create Any Context to &LIB_USER
GRANT CREATE ANY CONTEXT TO &LIB_USER
/
PROMPT Create &APP_USER
@c_user &APP_USER
GRANT CREATE SYNONYM TO &APP_USER
/

@endspool