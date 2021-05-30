CREATE OR REPLACE PACKAGE Trapit_Run AUTHID CURRENT_USER AS
/***************************************************************************************************
Name: trapit_run.pks                   Author: Brendan Furey                      Date: 08-June-2019

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

This file has the package spec for Trapit_Run, the unit test driver package. See README for API 
specification, and the other modules mentioned there for examples of use.

This package runs with Invoker rights, so that dynamic SQL calls to the test packages in the calling
schema do not require execute privilege to be granted to owning schema (if different from caller)

***************************************************************************************************/

PROCEDURE Run_Tests(
            p_group_nm                     VARCHAR2);

END Trapit_Run;
/
SHOW ERROR