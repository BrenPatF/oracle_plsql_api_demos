CREATE OR REPLACE PACKAGE BODY DML_API_TT_Bren AS
/***************************************************************************************************
Description: This package contains Bren (i.e. demo schema) DML procedures for Brendan's
             TRAPIT API testing framework demo test data

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan              11-Sep-2016 1.0   Initial
Brendan Furey        22-Oct-2016 1.1   TRAPIT name changes, UT->TT etc.

***************************************************************************************************/

/***************************************************************************************************

Ins_Emp: Inserts a record in job_statistics table for testing, setting the new ttid column to
         session id

***************************************************************************************************/
PROCEDURE Ins_Jbs (p_batch_job_id        VARCHAR2,    -- batch job id
                   p_file_name           VARCHAR2,    -- original input file name
                   p_records_loaded      PLS_INTEGER, -- records loaded to table
                   p_records_failed_et   PLS_INTEGER, -- records that failed to load via external table
                   p_records_failed_db   PLS_INTEGER, -- records that failed validation in the database
                   p_start_time          DATE,        -- job start time
                   p_end_time            DATE,        -- job end time
                   p_job_status          VARCHAR2) IS -- output record
  l_job_statistic_id  PLS_INTEGER;
BEGIN

  INSERT INTO job_statistics (
        job_statistic_id,
        batch_job_id,
        file_name,
        records_loaded,
        records_failed_et,
        records_failed_db,
        start_time,
        end_time,
        job_status,
        ttid
  ) VALUES (
        job_statistics_seq.NEXTVAL,
        p_batch_job_id,
        p_file_name,
        p_records_loaded,
        p_records_failed_et,
        p_records_failed_db,
        p_start_time,
        p_end_time,
        p_job_status,
        SYS_Context ('userenv', 'sessionid')
  ) RETURNING job_statistic_id
         INTO l_job_statistic_id;

END Ins_Jbs;

END DML_API_TT_Bren;
/
SHO ERR
