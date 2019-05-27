CREATE OR REPLACE PACKAGE DML_API_Bren AS
/***************************************************************************************************
Description: This package contains Bren (i.e. demo schema) DML procedures for Brendan's
              TRAPIT API testing framework demo test data

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        11-Sep-2016 1.0   Initial
Brendan Furey        22-Oct-2016 1.1   TRAPIT name changes, UT->TT etc.

***************************************************************************************************/

FUNCTION Ins_Jbs (p_batch_job_id        VARCHAR2,
                  p_file_name           VARCHAR2,
                  p_records_loaded      PLS_INTEGER,
                  p_records_failed_et   PLS_INTEGER,
                  p_records_failed_db   PLS_INTEGER,
                  p_start_time          DATE,
                  p_end_time            DATE,
                  p_job_status          VARCHAR2) RETURN PLS_INTEGER;

END DML_API_Bren;
/
SHO ERR
