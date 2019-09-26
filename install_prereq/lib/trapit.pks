CREATE OR REPLACE PACKAGE Trapit AS
/***************************************************************************************************
Name: trapit.pks                       Author: Brendan Furey                       Date: 26-May-2019

Package body component in the trapit_oracle_tester module. It requires a minimum Oracle 
database version of 12.2, owing to the use of v12.2 PL/SQL JSON features.

This module facilitates unit testing following 'The Math Function Unit Testing design pattern'.

    GitHub: https://github.com/BrenPatF/trapit_oracle_tester

====================================================================================================
|  Package     |  Notes                                                                            |
|===================================================================================================
| *Trapit*     |  Unit test utility package (Definer rights)                                       |
----------------------------------------------------------------------------------------------------
|  Trapit_Run  |  Unit test utility runner package (Invoker rights)                                |
====================================================================================================

This file has the Trapit package spec. See README for API specification, and the other modules
mentioned there for examples of use.

***************************************************************************************************/
TYPE scenarios_rec IS RECORD(
       delim                        VARCHAR2(10) := '|',
       scenarios_4lis               L4_chr_arr);

FUNCTION Get_Inputs (
            p_package_nm                   VARCHAR2,
            p_procedure_nm                 VARCHAR2)
            RETURN                         scenarios_rec;
PROCEDURE Set_Outputs (
            p_package_nm                   VARCHAR2,
            p_procedure_nm                 VARCHAR2,
            p_act_3lis                     L3_chr_arr);
PROCEDURE Add_Ttu(
            p_package_nm                   VARCHAR2,
            p_procedure_nm                 VARCHAR2, 
            p_group_nm                     VARCHAR2,
            p_active_yn                    VARCHAR2, 
            p_input_file                   VARCHAR2);

END Trapit;
/
SHOW ERROR