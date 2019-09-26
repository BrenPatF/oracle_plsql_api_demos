DEFINE app=&1
/***************************************************************************************************
Name: grant_utils_to_app.sql           Author: Brendan Furey                       Date: 08-Jun-2019

Grants privileges on Utils components from lib to app schema (passed as parameter).

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
|  install_sys.sql         |  sys script creates: lib and app schemas; input_dir directory; grants |
----------------------------------------------------------------------------------------------------
|  install_utils.sql       |  Creates base components, including Utils package, in lib schema      |
----------------------------------------------------------------------------------------------------
|  install_utils_tt.sql    |  Creates unit test components that require a minimum Oracle database  |
|                          |  version of 12.2 in lib schema                                        |
----------------------------------------------------------------------------------------------------
| *grant_utils_to_app.sql* |  Grants privileges on Utils components from lib to app schema         |
----------------------------------------------------------------------------------------------------
|  install_col_group.sql   |  Creates components for the Col_Group example in app schema           |
----------------------------------------------------------------------------------------------------
|  c_utils_syns.sql        |  Creates synonyms for Utils components in app schema to lib schema    |
====================================================================================================

This file grants privileges on Utils components from lib to app schema.

Grants applied:

    Privilege           Object                   Object Type
    ==================  =======================  ===================================================
    Execute             L1_chr_arr               Array (VARRAY)
    Execute             L1_num_arr               Array (VARRAY)
    Execute             chr_int_rec              Object
    Execute             chr_int_arr              Array (VARRAY)
    Execute             Utils                    Package

***************************************************************************************************/
PROMPT Granting Utils components to &app...
GRANT EXECUTE ON L1_chr_arr TO &app
/
GRANT EXECUTE ON L1_num_arr TO &app
/
GRANT EXECUTE ON chr_int_rec TO &app
/
GRANT EXECUTE ON chr_int_arr TO &app
/
GRANT EXECUTE ON Utils TO &app
/