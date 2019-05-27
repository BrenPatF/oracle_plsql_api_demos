CREATE OR REPLACE PACKAGE DML_API_TT_HR AS
/***************************************************************************************************
Description: This package contains HR DML procedures for Brendan's TRAPIT API testing
             framework demo test data

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        10-May-2016 1.0   Initial
Brendan Furey        09-Jul-2016 1.1   Added output parameter x_rec for new printing of inputs
Brendan Furey        11-Sep-2016 1.2   Defaulted extra parameters
Brendan Furey        22-Oct-2016 1.3   TRAPIT name changes, UT->TT etc.

***************************************************************************************************/

c_ln_pre        CONSTANT VARCHAR2(10) := 'LN_';
c_em_pre        CONSTANT VARCHAR2(10) := 'EM_';

FUNCTION Ins_Emp (p_emp_ind       PLS_INTEGER,
                  p_dep_id        PLS_INTEGER,
                  p_mgr_id        PLS_INTEGER,
                  p_job_id        VARCHAR2,
                  p_salary        PLS_INTEGER,
                  p_last_name     VARCHAR2 DEFAULT NULL,
                  p_email         VARCHAR2 DEFAULT NULL,
                  p_hire_date     DATE DEFAULT SYSDATE,
                  p_update_date   DATE DEFAULT SYSDATE) RETURN PLS_INTEGER;

END DML_API_TT_HR;
/
SHO ERR
/
