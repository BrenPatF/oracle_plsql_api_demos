WHENEVER SQLERROR CONTINUE
DEFINE app=&1
@..\initspool install_log_set
/***************************************************************************************************
Name: install_log_set.sql              Author: Brendan Furey                       Date: 17-Mar-2019

Installation script for the log_set_oracle module, excluding the unit test components that require a
minimum Oracle database version of 12.2. 

This is a logging framework that supports the writing of messages to log tables, along with various
optional data items that may be specified as parameters or read at runtime via system calls.

    GitHub: https://github.com/BrenPatF/log_set_oracle

Pre-requisite: Installation of the oracle_plsql_utils module:

    GitHub: https://github.com/BrenPatF/oracle_plsql_utils

There are two install scripts, of which the second is optional: 
- install_log_set.sql:    base code; requires base install of oracle_plsql_utils
- install_log_set_tt.sql: unit test code; requires unit test install section of oracle_plsql_utils

The lib schema refers to the schema in which oracle_plsql_utils was installed
====================================================================================================
|  Script                    |  Notes                                                              |
|==================================================================================================|
| *install_log_set.sql*      |  Creates base components, including Log_Set package, in lib schema  |
|----------------------------|---------------------------------------------------------------------|
|  install_log_set_tt.sql    |  Creates unit test components that require a minimum Oracle         |
|                            |  database version of 12.2 in lib schema                             |
|----------------------------|---------------------------------------------------------------------|
|  grant_log_set_to_app.sql  |  Grants privileges on Log_Set components from lib to app schema     |
|----------------------------|---------------------------------------------------------------------|
|  c_log_set_syns.sql        |  Creates synonyms for Log_Set components in app schema to lib       |
|                            |  schema                                                             |
====================================================================================================

This file has the install script for the lib schema, excluding the unit test components that require a
minimum Oracle database version of 12.2. This script should work in prior versions of Oracle,
including v10 and v11 (although it has not been tested on them).

Components created, with grants to app schema (if passed) via grant_log_set_to_app.sql:

    Types            Description
    ==========       ==================================================================================
    ctx_inp_obj      Context input object (name, put level, scope)
    ctx_inp_arr      (Varray) array of context input object
    ctx_out_obj      Context input object (name, value)
    ctx_out_arr      (Varray) array of context output object
   
    Sequences        Description
    =============    ===============================================================================
    log_configs_s    Log configurations sequence

    Tables           Description
    =============    ===============================================================================
    log_configs      Log configurations
    log_headers      Log headers
    log_lines        Log lines

    Packages         Description
    =============    ===============================================================================
    Log_Set          Logging package
    Log_Config       DML API package for log_configs table

    Seed Data        Description
    =============    ===============================================================================
    Log Configs      5 records inserted

***************************************************************************************************/

PROMPT Common types creation
PROMPT =====================
DROP TABLE log_lines
/
DROP TABLE log_headers
/
DROP TABLE log_configs
/

DROP TYPE ctx_inp_arr
/
DROP TYPE ctx_out_arr
/
CREATE OR REPLACE TYPE ctx_inp_obj IS OBJECT (
        ctx_nm                      VARCHAR2(30),
        put_lev                     INTEGER,                   -- null for print if line printed
        head_line_fg                VARCHAR2(1)
)
/
CREATE OR REPLACE TYPE ctx_inp_arr IS VARRAY(32767) OF ctx_inp_obj
/
CREATE OR REPLACE TYPE ctx_out_obj IS OBJECT (
        ctx_nm                      VARCHAR2(30),
        ctx_vl                      VARCHAR2(4000)
)
/
CREATE OR REPLACE TYPE ctx_out_arr IS VARRAY(32767) OF ctx_out_obj
/
PROMPT Common tables creation
PROMPT ======================

PROMPT Create table log_configs
CREATE TABLE log_configs(
        id                             INTEGER,
        config_key                     VARCHAR2(30),
        vsn_no                         INTEGER,
        active_yn                      VARCHAR2(1) CONSTRAINT active_ck CHECK (Nvl(active_yn, 'N') IN ('Y', 'N')),
        default_yn                     VARCHAR2(1) CONSTRAINT default_ck CHECK (Nvl(default_yn, 'N') IN ('Y', 'N')),
        default_error_yn               VARCHAR2(1) CONSTRAINT default_error_ck CHECK (Nvl(default_error_yn, 'N') IN ('Y', 'N')),
        singleton_yn                   VARCHAR2(1) CONSTRAINT singleton_ck CHECK (Nvl(singleton_yn, 'N') IN ('Y', 'N')),
        description                    VARCHAR2(4000),
        config_type                    VARCHAR2(100),
        creation_tmstp                 TIMESTAMP,
        put_lev                        INTEGER,
        put_lev_stack                  INTEGER,
        put_lev_cpu                    INTEGER,
        ctx_inp_lis                    ctx_inp_arr,
        put_lev_module                 INTEGER,
        put_lev_action                 INTEGER,
        put_lev_client_info            INTEGER,
        app_info_only_yn               VARCHAR2(1) CONSTRAINT app_info_only_ck CHECK (Nvl(app_info_only_yn, 'N') IN ('Y', 'N')),
        buff_len                       INTEGER,
        extend_len                     INTEGER,
        CONSTRAINT lcf_pk              PRIMARY KEY(id)
)
/
CREATE UNIQUE INDEX lcf_uk ON log_configs(config_key, vsn_no)
/
DROP SEQUENCE log_configs_s
/
CREATE SEQUENCE log_configs_s START WITH 1
/
PROMPT Create table log_headers
CREATE TABLE log_headers(
        id                             INTEGER,
        config_id,
        session_id                     VARCHAR2(30),
        session_user                   VARCHAR2(30),
        description                    VARCHAR2(4000),
        plsql_unit                     VARCHAR2(30),
        api_nm                         VARCHAR2(30),
        put_lev_min                    INTEGER,
        ctx_out_lis                    ctx_out_arr,
        creation_tmstp                 TIMESTAMP,
        closure_tmstp                  TIMESTAMP,
        CONSTRAINT lhd_pk              PRIMARY KEY(id),
        CONSTRAINT lhd_lcf_fk          FOREIGN KEY(config_id) REFERENCES log_configs(id)
)
/
DROP SEQUENCE log_headers_s
/
CREATE SEQUENCE log_headers_s START WITH 1
/
PROMPT Create table log_lines
CREATE TABLE log_lines(
        log_id,
        line_num                       INTEGER NOT NULL,
        session_line_num               INTEGER NOT NULL,
        line_type                      VARCHAR2(30),
        plsql_unit                     VARCHAR2(30),
        plsql_line                     INTEGER,
        group_text                     VARCHAR2(4000),
        line_text                      VARCHAR2(4000),
        action                         VARCHAR2(4000),
        call_stack                     VARCHAR2(2000),
        error_backtrace                VARCHAR2(4000),
        ctx_out_lis                    ctx_out_arr,
        put_lev_min                    INTEGER,
        err_num                        INTEGER,
        err_msg                        VARCHAR2(4000),
        creation_tmstp                 TIMESTAMP,
        creation_cpu_cs                INTEGER,
        CONSTRAINT lin_pk              PRIMARY KEY(log_id, line_num),
        CONSTRAINT lin_hdr_fk          FOREIGN KEY(log_id) REFERENCES log_headers (id)
)
/

PROMPT Packages creation
PROMPT =================

PROMPT Create package Log_Config
@log_config.pks
@log_config.pkb
PROMPT Create package Log_Set
@log_set.pks
@log_set.pkb

BEGIN
  Log_Config.Ins_Config(
        p_config_key            => 'SINGLETON',
        p_description           => 'Singleton, unbuffered: Good for debugging, does not need explicit Construct, default',
        p_config_type           => 'DEBUG',
        p_singleton_yn          => 'Y',
        p_default_yn            => 'Y');
  Log_Config.Ins_Config(
        p_config_key            => 'SINGLEBUF',
        p_description           => 'Singleton, buffered: Buffering maximises performance but may cause loss of last buffer in event of unhandled exception',
        p_singleton_yn          => 'Y',
        p_buff_len              => 100,
        p_extend_len            => 100);
  Log_Config.Ins_Config(
        p_config_key            => 'MULTILOG',
        p_description           => 'Multi-log, unbuffered: Unbuffered, so writes each line immediately as autonomous transaction');
  Log_Config.Ins_Config(
        p_config_key            => 'MULTIBUF',
        p_description           => 'Multi-log, buffered: Buffering maximises performance but may cause loss of last buffer in event of unhandled exception',
        p_buff_len              => 100,
        p_extend_len            => 100);
  Log_Config.Ins_Config(
        p_config_key            => 'ERROR',
        p_description           => 'Fatal errors: This is used by default for logging fatal errors',
        p_config_type           => 'ERROR',
        p_default_error_yn      => 'Y');
  Log_Config.Ins_Config(
      p_config_key              => 'APPINFO',
      p_description             => 'App info only: Good for real-time APIs, writes DBMS application info but does not write to tables',
      p_config_type             => 'INSTRUMENT',
      p_app_info_only_yn        => 'Y',
      p_put_lev_module          => 1,
      p_put_lev_client_info     => 1);
  Log_Config.Ins_Config(
      p_config_key              => 'BATCH',
      p_description             => 'Batch jobs: Unbuffered, so writes each line immediately as autonomous transaction, and writes DBMS application info',
      p_config_type             => 'INSTRUMENT',
      p_put_lev_module          => 1,
      p_put_lev_client_info     => 1);
END;
/

PROMPT Grant access to &app (skip if none passed)
WHENEVER SQLERROR EXIT
EXEC IF '&app' = 'none' THEN RAISE_APPLICATION_ERROR(-20000, 'Skipping schema grants'); END IF;
@grant_log_set_to_app &app

@..\endspool