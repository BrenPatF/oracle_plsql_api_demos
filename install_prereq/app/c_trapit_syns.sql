DEFINE lib=&1
/***************************************************************************************************
Name: c_trapit_syns.sql                Author: Brendan Furey                       Date: 08-Jun-2019

Creates synonyms for Trapit components in app schema to lib schema.

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
|  grant_trapit_to_app.sql  |  Grants privileges on Trapit components from lib to app schema       |
|---------------------------|----------------------------------------------------------------------|
| *c_trapit_syns.sql*       |  Creates synonyms for Trapit components in app schema to lib schema  |
====================================================================================================

Creates synonyms for Trapit components in app schema to lib schema.

Synonyms created:

    Synonym             Object Type
    ==================  ============================================================================
    L2_chr_arr          Array (VARRAY)
    L3_chr_arr          Array (VARRAY)
    L4_chr_arr          Array (VARRAY)
    Trapit              Package
    Trapit_Run          Package

***************************************************************************************************/
PROMPT Creating synonyms for &lib Trapit components...
CREATE OR REPLACE SYNONYM L2_chr_arr FOR &lib..L2_chr_arr
/
CREATE OR REPLACE SYNONYM L3_chr_arr FOR &lib..L3_chr_arr
/
CREATE OR REPLACE SYNONYM L4_chr_arr FOR &lib..L4_chr_arr
/
CREATE OR REPLACE SYNONYM Trapit FOR &lib..Trapit
/
CREATE OR REPLACE SYNONYM Trapit_Run FOR &lib..Trapit_Run
/
