CREATE OR REPLACE PACKAGE BODY Trapit_Run AS
/***************************************************************************************************
Name: trapit_run.pkb                   Author: Brendan Furey                      Date: 08-June-2019

Package body component in the trapit_oracle_tester module. It requires a minimum Oracle 
database version of 12.2, owing to the use of v12.2 PL/SQL JSON features.

This module facilitates unit testing following 'The Math Function Unit Testing design pattern'.

    GitHub: https://github.com/BrenPatF/trapit_oracle_tester

====================================================================================================
|  Package     |  Notes                                                                            |
|===================================================================================================
| Trapit       |  Unit test utility package (Definer rights)                                       |
----------------------------------------------------------------------------------------------------
| *Trapit_Run* |  Unit test utility runner package (Invoker rights)                                |
====================================================================================================

This file has the Trapit_Run package body. See README for API specification, and the other modules
mentioned there for examples of use.

This package runs with Invoker rights, so that dynamic SQL calls to the test packages in the calling
schema do not require execute privilege to be granted to owning schema (if different from caller).
***************************************************************************************************/
/***************************************************************************************************

Run_Tests: Run tests

***************************************************************************************************/
PROCEDURE Run_Tests(
            p_group_nm                     VARCHAR2) IS

  TYPE tt_units_arr IS VARRAY(1000) OF tt_units%ROWTYPE;
  l_tt_units_lis    tt_units_arr;
  PROCEDURE Run_TT_Package (p_package_proc_nm VARCHAR2) IS
  BEGIN

    EXECUTE IMMEDIATE 'BEGIN ' || p_package_proc_nm || '; END;';

  END Run_TT_Package;

BEGIN

  SELECT *
    BULK COLLECT INTO l_tt_units_lis
    FROM tt_units
  WHERE active_yn = 'Y'
    AND group_nm = p_group_nm;
  FOR i IN 1..l_tt_units_lis.COUNT LOOP

    Run_TT_Package(l_tt_units_lis(i).package_nm || '.' ||  l_tt_units_lis(i).procedure_nm);
    COMMIT;

  END LOOP;

END Run_Tests;

END Trapit_Run;
/
SHO ERR