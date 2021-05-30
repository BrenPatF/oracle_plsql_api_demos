DEFINE app=&1
/***************************************************************************************************
Name: grant_trapit_to_app.sql          Author: Brendan Furey                       Date: 08-Jun-2019

Grants privileges on Trapit components from lib to app schema (passed as parameter).

This module facilitates unit testing in Oracle PL/SQL following 'The Math Function Unit Testing 
design pattern', as described here: 

    The Math Function Unit Testing design pattern, implemented in nodejs:
    https://github.com/BrenPatF/trapit_nodejs_tester

This module on GitHub:

    Oracle PL/SQL unit testing module
    https://github.com/BrenPatF/trapit_oracle_tester

Pre-requisite: Installation of the oracle_plsql_utils module (base install):

    GitHub: https://github.com/BrenPatF/oracle_plsql_utils

The lib schema refers to the schema in which oracle_plsql_utils was installed.
====================================================================================================
|  Script                   |  Notes                                                               |
|==================================================================================================|
|  install_trapit.sql       |  Creates base components, including Trapit package, in lib schema    |
|---------------------------|----------------------------------------------------------------------|
| *grant_trapit_to_app.sql* |  Grants privileges on Trapit components from lib to app schema       |
|---------------------------|----------------------------------------------------------------------|
|  c_trapit_syns.sql        |  Creates synonyms for Trapit components in app schema to lib schema  |
====================================================================================================

This file grants privileges on Trapit components from lib to app schema.

Grants applied:

    Privilege           Object                   Object Type
    ==================  =======================  ===================================================
    Execute             L2_chr_arr               Array (VARRAY)
    Execute             L3_chr_arr               Array (VARRAY)
    Execute             L4_chr_arr               Array (VARRAY)
    Execute             Trapit                   Package
    Execute             Trapit_Run               Package

***************************************************************************************************/
PROMPT Granting Trapit components to &app...
GRANT EXECUTE ON L2_chr_arr TO &app
/
GRANT EXECUTE ON L3_chr_arr TO &app
/
GRANT EXECUTE ON L4_chr_arr TO &app
/
GRANT EXECUTE ON Trapit TO &app
/
GRANT EXECUTE ON Trapit_Run TO &app
/
