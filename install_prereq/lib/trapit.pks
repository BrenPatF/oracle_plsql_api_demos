CREATE OR REPLACE PACKAGE Trapit AS
/***************************************************************************************************
Name: trapit.pks                       Author: Brendan Furey                       Date: 26-May-2019

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
| *Trapit*     |  Unit test utility package (Definer rights)                                       |
|--------------------------------------------------------------------------------------------------|
|  Trapit_Run  |  Unit test driver package (Invoker rights)                                        |
====================================================================================================

This file has the package spec for Trapit, the unit test utility package. See README for API 
specification, and the other modules mentioned there for examples of use

***************************************************************************************************/

FUNCTION Get_Inputs(
            p_unit_test_package_nm         VARCHAR2,
            p_purely_wrap_api_function_nm  VARCHAR2)
            RETURN                         L4_chr_arr;
PROCEDURE Set_Outputs(
            p_unit_test_package_nm         VARCHAR2,
            p_purely_wrap_api_function_nm  VARCHAR2,
            p_title                        VARCHAR2 := NULL,
            p_act_3lis                     L3_chr_arr,
            p_err_2lis                     L2_chr_arr);
PROCEDURE Add_Ttu(
            p_unit_test_package_nm         VARCHAR2,
            p_purely_wrap_api_function_nm  VARCHAR2, 
            p_group_nm                     VARCHAR2,
            p_active_yn                    VARCHAR2, 
            p_input_file                   VARCHAR2,
            p_title                        VARCHAR2 := NULL);
FUNCTION Get_Active_TT_Units(
            p_group_nm                     VARCHAR2)
            RETURN                         L1_chr_arr PIPELINED;

END Trapit;
/
SHOW ERROR