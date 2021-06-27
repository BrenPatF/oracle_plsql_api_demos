CREATE OR REPLACE PACKAGE BODY Trapit_Run AS
/***************************************************************************************************
Name: trapit_run.pkb                   Author: Brendan Furey                      Date: 08-June-2019

Package body component in the trapit_oracle_tester module. It requires a minimum Oracle 
database version of 12.2, owing to the use of v12.2 PL/SQL JSON features.

This module facilitates unit testing in Oracle PL/SQL following 'The Math Function Unit Testing 
design pattern', as described here: 

    The Math Function Unit Testing design pattern, implemented in nodejs:
    https://github.com/BrenPatF/trapit_nodejs_tester

This module on GitHub:

    Oracle PL/SQL unit testing module
    https://github.com/BrenPatF/trapit_oracle_tester

====================================================================================================
|  Package     |  Notes                                                                            |
|==================================================================================================|
| Trapit       |  Unit test utility package (Definer rights)                                       |
|--------------|-----------------------------------------------------------------------------------|
| *Trapit_Run* |  Unit test driver package (Invoker rights)                                        |
====================================================================================================

This file has the package body for Trapit_Run, the unit test driver package. See README for API 
specification, and the other modules mentioned there for examples of use.

This package runs with Invoker rights, so that dynamic SQL calls to the test packages in the calling
schema do not require execute privilege to be granted to owning schema (if different from caller)

***************************************************************************************************/

/***************************************************************************************************

run_A_Test: Run a single unit test, using the name of the package function passed in to make a call
            via dynamic SQL. The function must have the signature expected for the Math Function 
            Unit Testing design pattern, namely:

            Input parameter: 3-level list (type L3_chr_arr) with test inputs as group/record/field
            Return Value: 2-level list (type L2_chr_arr) with test outputs as group/record (with 
                          record as delimited fields string)

***************************************************************************************************/
PROCEDURE run_A_Test(p_package_function VARCHAR2, p_title VARCHAR2)  IS

  l_act_3lis                     L3_chr_arr := L3_chr_arr();
  l_sces_4lis                    L4_chr_arr;
  l_package_function_lis         L1_chr_arr := Utils.Split_Values(p_string => p_package_function, 
                                                                  p_delim  => '.');
  l_err_2lis                     L2_chr_arr := L2_chr_arr();
BEGIN

  l_sces_4lis := Trapit.Get_Inputs(p_unit_test_package_nm        => l_package_function_lis(1),
                                   p_purely_wrap_api_function_nm => l_package_function_lis(2));
  l_act_3lis.EXTEND(l_sces_4lis.COUNT);
  l_err_2lis.EXTEND(l_sces_4lis.COUNT);
  FOR i IN 1..l_sces_4lis.COUNT LOOP

    BEGIN
      EXECUTE IMMEDIATE 'BEGIN :1 := ' || p_package_function || '(:2); END;'
        USING OUT l_act_3lis(i), l_sces_4lis(i);
    EXCEPTION
      WHEN OTHERS THEN
        l_err_2lis(i) := L1_chr_arr(SQLERRM, DBMS_Utility.Format_Error_Backtrace);
    END;

  END LOOP;
  Trapit.Set_Outputs(p_unit_test_package_nm        => l_package_function_lis(1),
                     p_purely_wrap_api_function_nm => l_package_function_lis(2),
                     p_title                       => p_title,
                     p_act_3lis                    => l_act_3lis,
                     p_err_2lis                    => l_err_2lis);

END run_A_Test;

/***************************************************************************************************

Run_Tests: Run tests for the unit test group

***************************************************************************************************/
PROCEDURE Run_Tests(
            p_group_nm                     VARCHAR2) IS

  l_ttu_lis                    L1_chr_arr;
BEGIN

  DBMS_Session.Set_NLS('nls_date_format', '''DD-MON-YYYY''');--c_date_fmt); - constant did not work

  FOR r IN (SELECT COLUMN_VALUE FROM TABLE(Trapit.Get_Active_TT_Units(p_group_nm => p_group_nm))) LOOP

    l_ttu_lis := Utils.Split_Values(p_string => r.COLUMN_VALUE, 
                                    p_delim  => '|');
    run_A_Test(p_package_function => l_ttu_lis(1), p_title => l_ttu_lis(2));
    COMMIT;

  END LOOP;

END Run_Tests;

END Trapit_Run;
/
SHO ERR