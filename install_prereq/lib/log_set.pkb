CREATE OR REPLACE PACKAGE BODY Log_Set AS
/***************************************************************************************************
Name: log_set.pkb                      Author: Brendan Furey                       Date: 17-Mar-2019

Package body component in the log_set_oracle module. This is a logging framework that supports the
writing of messages to log tables, along with various optional data items that may be specified as
parameters or read at runtime via system calls.

    GitHub: https://github.com/BrenPatF/log_set_oracle

====================================================================================================
|  Package     |  Notes                                                                            |
|==================================================================================================|
| *Log_Set*    |  Logging package                                                                  |
|--------------|-----------------------------------------------------------------------------------|
|  Log_Config  |  DML API package for log configs table                                            |
====================================================================================================

This file has the Log_Set package body. See README for API specification, and the main_col_group.sql
script for simple examples of use

***************************************************************************************************/

DATE_TIME_FMT                 CONSTANT VARCHAR2(30) := 'dd-Mon-yyyy hh24:mi:ss';
SESSION_ID                    CONSTANT VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSIONID');
SESSION_USER                  CONSTANT VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSION_USER');
LINE_TYPE_ERROR               CONSTANT VARCHAR2(30) := 'ERROR';
TYPE log_inp_rec IS RECORD ( -- log input line record type
        header                    log_headers%ROWTYPE,
        config_rec                log_configs%ROWTYPE -- config record
);
TYPE log_out_arr IS VARRAY(32767) OF log_lines%ROWTYPE;
TYPE log_rec IS RECORD ( -- log output record type
        inps                      log_inp_rec, -- input record
        ctx_out_lis               ctx_out_arr, -- array of output contexts (name, value) at header level
        out_lis                   log_out_arr, -- output list of records
        lines_buf                 PLS_INTEGER, -- number of lines in buffer
        lines_tab                 PLS_INTEGER, -- number of lines put to table
        log_id                    PLS_INTEGER  -- log id
);
TYPE log_arr IS                   TABLE OF log_rec INDEX BY BINARY_INTEGER;
g_log_lis                         log_arr;
g_singleton_id                    PLS_INTEGER;
g_session_line_num                PLS_INTEGER := 0;

/***************************************************************************************************

Init: Reset the two package body globals

***************************************************************************************************/
PROCEDURE Init IS
BEGIN

  g_singleton_id     := NULL;
  g_session_line_num := 0;

END Init;

/***************************************************************************************************

get_Context: Return the USERENV system context value for the name passed

***************************************************************************************************/
FUNCTION get_Context(
            p_ctx_nm                       VARCHAR2)   -- context name
            RETURN                         VARCHAR2 IS -- context value
BEGIN
  RETURN SYS_CONTEXT('USERENV', p_ctx_nm);
END get_Context;

/***************************************************************************************************

ok_To_Put: Return True if the item is to be put, based on put level and level minimum

***************************************************************************************************/
FUNCTION ok_To_Put(
            p_lev_min                      PLS_INTEGER, -- put level minimum
            p_lev_field                    PLS_INTEGER) -- put level for item
            RETURN                         BOOLEAN IS   -- True if ok to put
BEGIN
  RETURN p_lev_field >= p_lev_min;
END ok_To_Put;

/***************************************************************************************************

get_Contexts: Return array of output contexts - name, value pairs

***************************************************************************************************/
FUNCTION get_Contexts(
            p_ctx_inp_lis                  ctx_inp_arr,   -- array of input contexts (name, level, scope)
            p_put_lev_min                  PLS_INTEGER,   -- put level minimum
            p_head_line_fg                 VARCHAR2)      -- scope flag ('H', 'L', 'B')
            RETURN                         ctx_out_arr IS -- array of output contexts (name, value)

  l_ctx_out_obj       ctx_out_obj;
  l_ctx_out_lis       ctx_out_arr;

BEGIN

  IF p_ctx_inp_lis IS NOT NULL THEN

    FOR i IN 1..p_ctx_inp_lis.COUNT LOOP

      IF p_ctx_inp_lis(i).head_line_fg IN (p_head_line_fg, 'B') AND 
        ok_To_Put(p_put_lev_min, p_ctx_inp_lis(i).put_lev) THEN

        l_ctx_out_obj := ctx_out_obj(p_ctx_inp_lis(i).ctx_nm, get_Context(p_ctx_inp_lis(i).ctx_nm));

        IF l_ctx_out_lis IS NULL THEN
          l_ctx_out_lis := ctx_out_arr(l_ctx_out_obj);
        ELSE
          l_ctx_out_lis.EXTEND;
          l_ctx_out_lis(l_ctx_out_lis.COUNT) := l_ctx_out_obj;
        END IF;

      END IF;

    END LOOP;

  END IF;
  RETURN l_ctx_out_lis;

END get_Contexts;

/***************************************************************************************************

Con_Construct_Rec: Constructor function for construct_rec type

***************************************************************************************************/
FUNCTION Con_Construct_Rec(
            p_config_key                   VARCHAR2 := NULL,    -- config key
            p_description                  VARCHAR2 := NULL,    -- log description
            p_plsql_unit                   VARCHAR2 := NULL,    -- PL/SQL unit
            p_api_nm                       VARCHAR2 := NULL,    -- API name, eg procedure name
            p_put_lev_min                  PLS_INTEGER := NULL, -- put level minimum
            p_do_close                     BOOLEAN := NULL)     -- True if to close at once
            RETURN                         construct_rec IS     -- constructed record
  l_construct_rec                construct_rec := CONSTRUCT_DEF;
BEGIN

  IF p_config_key    IS NULL AND
     p_description   IS NULL AND
     p_plsql_unit    IS NULL AND
     p_api_nm        IS NULL AND
     p_put_lev_min   IS NULL AND
     p_do_close      IS NULL THEN

    l_construct_rec.null_yn    := 'Y';
  
  ELSE

    l_construct_rec.config_key         := p_config_key;
    l_construct_rec.header.description := p_description;
    l_construct_rec.header.plsql_unit  := p_plsql_unit;
    l_construct_rec.header.api_nm      := p_api_nm;
    l_construct_rec.header.put_lev_min := Nvl(p_put_lev_min, 0);
    l_construct_rec.do_close           := Nvl(p_do_close, FALSE);

  END IF;
  RETURN l_construct_rec;

END Con_Construct_Rec;

/***************************************************************************************************

Con_Line_Rec:  Constructor function for line_rec type

***************************************************************************************************/
FUNCTION Con_Line_Rec(
            p_line_type                    VARCHAR2 := NULL,    -- line type, eg 'ERROR' etc., not validated
            p_plsql_unit                   VARCHAR2 := NULL,    -- PL/SQL package name, as given by $$PLSQL_UNIT
            p_plsql_line                   VARCHAR2 := NULL,    -- PL/SQL line number, as given by $$PLSQL_LINE
            p_group_text                   VARCHAR2 := NULL,    -- free text that can be used to group lines
            p_action                       VARCHAR2 := NULL,    -- action that can be used as the action in DBMS_Application_Info.Set_Action, and logged with a line
            p_put_lev_min                  PLS_INTEGER := NULL, -- minimum put level
            p_err_num                      PLS_INTEGER := NULL, -- error number when passed explicitly, also set to SQLCODE by Write_Other_Error
            p_err_msg                      VARCHAR2 := NULL,    -- error message when passed explicitly, also set to SQLERRM by Write_Other_Error
            p_call_stack                   VARCHAR2 := NULL,    -- call stack set using DBMS_Utility.Format_Call_Stack
            p_do_close                     BOOLEAN := NULL)     -- True if to close after putting
            RETURN                         line_rec IS          -- constructed record
  l_line_rec                      line_rec := LINE_DEF;
BEGIN

  IF p_line_type     IS NULL AND
     p_plsql_unit    IS NULL AND
     p_plsql_line    IS NULL AND
     p_group_text    IS NULL AND
     p_action        IS NULL AND
     p_put_lev_min   IS NULL AND
     p_err_num       IS NULL AND
     p_err_msg       IS NULL AND
     p_call_stack    IS NULL AND
     p_do_close      IS NULL THEN

    l_line_rec.null_yn    := 'Y';
  
  ELSE

    l_line_rec.line.line_type     := p_line_type;
    l_line_rec.line.plsql_unit    := p_plsql_unit;
    l_line_rec.line.plsql_line    := p_plsql_line;
    l_line_rec.line.group_text    := p_group_text;
    l_line_rec.line.action        := p_action;
    l_line_rec.line.put_lev_min   := Nvl(p_put_lev_min, 0);
    l_line_rec.line.err_num       := p_err_num;
    l_line_rec.line.err_msg       := p_err_msg;
    l_line_rec.line.call_stack    := p_call_stack;
    l_line_rec.do_close           := Nvl(p_do_close, FALSE);

  END IF;
  RETURN l_line_rec;

END Con_Line_Rec;

/***************************************************************************************************

Construct: Base log constructor function, returning the log id. The log info is stored in a new 
           element of the global array g_log_lis

***************************************************************************************************/
FUNCTION Construct(
            p_construct_rec                construct_rec := CONSTRUCT_DEF) -- construct record
            RETURN                         PLS_INTEGER IS                  -- log id

  l_inps                         log_inp_rec;
  l_log                          log_rec;
  l_config_key                   log_configs.config_key%TYPE := p_construct_rec.config_key;
  l_config_rec                   log_configs%ROWTYPE;
BEGIN

  l_inps.header.description      := p_construct_rec.header.description;
  l_inps.header.plsql_unit       := p_construct_rec.header.plsql_unit;
  l_inps.header.api_nm           := p_construct_rec.header.api_nm;
  l_inps.header.put_lev_min      := Nvl(p_construct_rec.header.put_lev_min, 0);
  l_inps.header.creation_tmstp   := SYSTIMESTAMP;
  l_log.lines_buf         := 0;
  l_log.lines_tab         := 0;

  IF l_config_key IS NULL THEN 
    l_config_key := Log_Config.Get_Default_Config;
  END IF;

  l_config_rec := Log_Config.Get_Config(p_config_key => l_config_key);
  l_inps.config_rec := l_config_rec;
  l_log.log_id := log_headers_s.NEXTVAL;

  IF l_config_rec.singleton_yn = 'Y' THEN
    IF g_singleton_id IS NOT NULL THEN
      Raise_Error(p_err_msg => l_config_key || ' is singleton type and log ' || 
        g_singleton_id || ' already constructed');
    ELSE
      g_singleton_id := l_log.log_id;
    END IF;
  END IF;

  IF ok_To_Put(p_construct_rec.header.put_lev_min, l_config_rec.put_lev_module) THEN
    DBMS_Application_Info.Set_Module(Nvl(p_construct_rec.header.plsql_unit, $$PLSQL_UNIT) || ': Log id ' || l_log.log_id, p_construct_rec.header.description);
  END IF;

  l_log.inps := l_inps;
  l_log.ctx_out_lis := get_Contexts(p_ctx_inp_lis       => l_config_rec.ctx_inp_lis,
                                    p_put_lev_min       => p_construct_rec.header.put_lev_min,
                                    p_head_line_fg      => 'H');
  g_log_lis(l_log.log_id) := l_log;
  
  IF p_construct_rec.do_close THEN
    Close_Log(l_log.log_id);
  END IF;

  RETURN l_log.log_id;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    Raise_Error(p_err_msg => l_config_key || ' config not found');
END Construct;

/***************************************************************************************************

Construct: Log constructor function, returning the log id. This version also puts a line, after
           calling the base constructor

***************************************************************************************************/
FUNCTION Construct(
            p_line_text                    VARCHAR2,                       -- line text to put
            p_construct_rec                construct_rec := CONSTRUCT_DEF, -- construct record
            p_line_rec                     line_rec := LINE_DEF)           -- line record
            RETURN                         PLS_INTEGER IS                  -- log id

  l_log_id         PLS_INTEGER := Construct(p_construct_rec => p_construct_rec);

BEGIN

  Put_Line(p_log_id     => l_log_id,
           p_line_text  => p_line_text,
           p_line_rec   => p_line_rec);

  IF p_line_rec.do_close THEN
    Close_Log(l_log_id);
  END IF;
  
  RETURN l_log_id;

END Construct;

/***************************************************************************************************

Construct: Log constructor function, returning the log id. This version also puts a list of lines,
           after calling the base constructor

***************************************************************************************************/
FUNCTION Construct(
            p_line_lis                     L1_chr_arr,                     -- list of lines to put
            p_construct_rec                construct_rec := CONSTRUCT_DEF, -- construct record
            p_line_rec                     line_rec := LINE_DEF)           -- line record
            RETURN                         PLS_INTEGER IS                  -- log id

  l_log_id         PLS_INTEGER := Construct(p_construct_rec => p_construct_rec);

BEGIN

  Put_List(p_log_id     => l_log_id,
           p_line_lis   => p_line_lis,
           p_line_rec   => p_line_rec);

  IF p_line_rec.do_close THEN
    Close_Log(l_log_id);
  END IF;

  RETURN l_log_id;

END Construct;

/***************************************************************************************************

ins_Header: Insert into log headers table, if applicable

***************************************************************************************************/
PROCEDURE ins_Header(
            p_log                          log_rec) IS -- log record
BEGIN

  IF p_log.lines_tab = 0 AND Nvl(p_log.inps.config_rec.app_info_only_yn, 'N') != 'Y' THEN
    INSERT INTO log_headers(
        id,
        session_id,
        session_user,
        config_id,
        description,
        plsql_unit,
        api_nm,
        put_lev_min,
        ctx_out_lis,
        creation_tmstp
    ) VALUES (
        p_log.log_id,
        Log_Set.SESSION_ID,
        SESSION_USER,
        p_log.inps.config_rec.id,
        p_log.inps.header.description,
        p_log.inps.header.plsql_unit,
        p_log.inps.header.api_nm,
        p_log.inps.header.put_lev_min,
        p_log.ctx_out_lis,
        p_log.inps.header.creation_tmstp
    );
  END IF;

END ins_Header;

/***************************************************************************************************

ins_Lines: Insert into log lines table using bulk insert

***************************************************************************************************/
PROCEDURE ins_Lines(
            p_log                          log_rec) IS -- log record
BEGIN

  FORALL i IN 1..p_log.lines_buf
    INSERT INTO log_lines(
        log_id,
        line_num,
        session_line_num,
        line_type,
        plsql_unit,
        plsql_line,
        group_text,
        line_text,
        action,
        call_stack,
        error_backtrace,
        ctx_out_lis,
        put_lev_min,
        err_num,
        err_msg,
        creation_tmstp,
        creation_cpu_cs
    ) VALUES (
        p_log.log_id,
        p_log.out_lis(i).line_num,
        p_log.out_lis(i).session_line_num,
        p_log.out_lis(i).line_type,
        p_log.out_lis(i).plsql_unit,
        p_log.out_lis(i).plsql_line,
        p_log.out_lis(i).group_text,
        p_log.out_lis(i).line_text,
        p_log.out_lis(i).action,
        p_log.out_lis(i).call_stack,
        p_log.out_lis(i).error_backtrace,
        p_log.out_lis(i).ctx_out_lis,
        p_log.out_lis(i).put_lev_min,
        p_log.out_lis(i).err_num,
        p_log.out_lis(i).err_msg,
        p_log.out_lis(i).creation_tmstp,
        p_log.out_lis(i).creation_cpu_cs
    );

END ins_Lines;

/***************************************************************************************************

flush_Buf: Flush the buffer to tables using autonomous transaction. Checks whether the log is due to
          be written, and deletes from array if not, and also on closing

***************************************************************************************************/
PROCEDURE flush_Buf(
            p_log                          log_rec,             -- log record
            p_do_close                     BOOLEAN := FALSE) IS -- True if to close log
  PRAGMA AUTONOMOUS_TRANSACTION;
  l_config_rec                   log_configs%ROWTYPE := p_log.inps.config_rec;
BEGIN

  IF NOT ok_To_Put(p_log.inps.header.put_lev_min, l_config_rec.put_lev) THEN
    g_log_lis.DELETE(p_log.log_id);
    RETURN;
  END IF;

  ins_Header(p_log => p_log);
  ins_Lines(p_log => p_log);

  IF p_do_close THEN

    IF l_config_rec.singleton_yn = 'Y' THEN
      g_singleton_id := NULL;
    END IF;

    UPDATE log_headers
       SET closure_tmstp = SYSTIMESTAMP
     WHERE id = p_log.log_id;

    IF ok_To_Put(p_log.inps.header.put_lev_min, l_config_rec.put_lev_module) THEN
      DBMS_Application_Info.Set_Action('Log id ' || p_log.log_id || ' closed at ' || 
                                       To_Char(SYSTIMESTAMP, DATE_TIME_FMT));
    END IF;

    g_log_lis.DELETE(p_log.log_id);
  END IF;
  COMMIT;

END flush_Buf;

/***************************************************************************************************

get_Out: Returns log output record

***************************************************************************************************/
FUNCTION get_Out(            
            p_log                          log_rec,              -- log record
            p_line_text                    VARCHAR2,             -- line text to put
            p_line_rec                     line_rec := LINE_DEF) -- line record
            RETURN                         log_lines%ROWTYPE IS        -- log output record
  l_out_rec                      log_lines%ROWTYPE := p_line_rec.line;
  l_ctx_inp_lis                  ctx_inp_arr;
  l_config_rec                   log_configs%ROWTYPE := p_log.inps.config_rec;
BEGIN

  l_out_rec.line_num    := p_log.lines_tab + p_log.lines_buf + 1;
  l_out_rec.line_text   := p_line_text;

  l_out_rec.ctx_out_lis := get_Contexts(p_ctx_inp_lis       => l_config_rec.ctx_inp_lis, 
                                        p_put_lev_min       => p_line_rec.line.put_lev_min,
                                        p_head_line_fg            => 'L');

  IF p_line_rec.line.call_stack IS NOT NULL THEN
    l_out_rec.call_stack := p_line_rec.line.call_stack;
  ELSIF ok_To_Put(p_line_rec.line.put_lev_min, l_config_rec.put_lev_stack) THEN
    l_out_rec.call_stack := DBMS_Utility.Format_Call_Stack;
  END IF;

  IF ok_To_Put(p_line_rec.line.put_lev_min, l_config_rec.put_lev_cpu) THEN
    l_out_rec.creation_cpu_cs := DBMS_Utility.Get_CPU_Time;
  END IF;
  RETURN l_out_rec;

END get_Out;

/***************************************************************************************************

get_Log_If_Exists: Returns log record for id if it exists, and if not raises an error

***************************************************************************************************/
FUNCTION get_Log_If_Exists(
            p_log_id                       PLS_INTEGER, --log id
            p_log_lis                      log_arr)     -- log array
            RETURN                         log_rec IS   -- log record
  l_close_tmstp_chr           VARCHAR2(30);
BEGIN

  IF p_log_lis.EXISTS(p_log_id) THEN

    RETURN p_log_lis(p_log_id);

  ELSE

    BEGIN
      SELECT To_Char(closure_tmstp, DATE_TIME_FMT)
        INTO l_close_tmstp_chr
        FROM log_headers
      WHERE id = p_log_id;
      Raise_Error(p_err_msg => 'Log ' || p_log_id || ' closed at: ' || l_close_tmstp_chr);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Raise_Error(p_err_msg => 'Log ' || p_log_id || ' not found');
    END;

  END IF;

END get_Log_If_Exists;

/***************************************************************************************************

get_New_Log: Returns new log by adding new line to buffer of existing log, flushing if full

***************************************************************************************************/
FUNCTION get_New_Log(
            p_log                          log_rec,   -- existing log
            p_line_text                    VARCHAR2,  -- line text to put
            p_line_rec                     line_rec)  -- line record
            RETURN                         log_rec IS -- new log with line added
  l_out_rec                      log_lines%ROWTYPE;
  l_log                          log_rec := p_log;
  l_config_rec                   log_configs%ROWTYPE := p_log.inps.config_rec;
BEGIN

  l_out_rec := get_Out(            
                  p_log         => l_log,
                  p_line_text   => p_line_text,
                  p_line_rec    => p_line_rec);

  g_session_line_num := g_session_line_num + 1;
  l_out_rec.session_line_num := g_session_line_num;
  l_log.lines_buf := l_log.lines_buf + 1;
  
  IF l_log.out_lis IS NULL THEN
    l_log.out_lis := log_out_arr();
  END IF;
  
  IF l_log.lines_buf > l_log.out_lis.COUNT THEN
  
    l_log.out_lis.EXTEND(l_config_rec.extend_len);
  
  END IF;
  l_log.out_lis(l_log.lines_buf) := l_out_rec;
  
  IF l_log.lines_buf = l_config_rec.buff_len THEN
    flush_Buf(l_log);
    l_log.lines_tab := l_log.lines_tab + l_log.lines_buf;
    l_log.lines_buf := 0;
  
  END IF;
  RETURN l_log;

END get_New_Log;

/***************************************************************************************************

Put_Line: Put a line to log buffer

***************************************************************************************************/
PROCEDURE Put_Line(
            p_line_text                    VARCHAR2,                -- line text to put
            p_log_id                       PLS_INTEGER := NULL,     -- log id
            p_line_rec                     line_rec := LINE_DEF) IS -- line record
  l_put_lev                   PLS_INTEGER;
  l_log                       log_rec;
  l_log_id                    PLS_INTEGER := Nvl(p_log_id, g_singleton_id);
  l_config                    log_configs%ROWTYPE;
  l_line_rec                  line_rec := p_line_rec;

BEGIN
  IF l_log_id IS NULL THEN
    l_log_id := Construct;
  END IF;
  l_log := get_Log_If_Exists(p_log_id  => l_log_id,
                             p_log_lis => g_log_lis);
  l_config := l_log.inps.config_rec;
  l_put_lev := l_config.put_lev;
  l_line_rec.line.put_lev_min := Nvl(l_line_rec.line.put_lev_min, 0);
  l_line_rec.line.creation_tmstp := SYSTIMESTAMP;
  IF ok_To_Put(l_log.inps.header.put_lev_min, l_put_lev) AND
     ok_To_Put(l_line_rec.line.put_lev_min, l_put_lev) THEN

    IF ok_To_Put(l_line_rec.line.put_lev_min, l_config.put_lev_action) THEN
      DBMS_Application_Info.Set_Action(l_line_rec.line.action);
    END IF;

    IF ok_To_Put(l_line_rec.line.put_lev_min, l_config.put_lev_client_info) THEN
      DBMS_Application_Info.Set_Client_Info(p_line_text);
    END IF;

    IF Nvl(l_config.app_info_only_yn, 'N') = 'N' THEN 

      g_log_lis(l_log_id) := get_New_Log(
                                p_log                          => l_log,
                                p_line_text                    => p_line_text,
                                p_line_rec                     => l_line_rec);
    END IF;

  END IF;

  IF p_line_rec.do_close THEN
    Close_Log(l_log_id);
  END IF;

END Put_Line;

/***************************************************************************************************

Put_List: Put a list of lines to log buffer

***************************************************************************************************/
PROCEDURE Put_List(
            p_line_lis                     L1_chr_arr,
            p_log_id                       PLS_INTEGER := NULL,
            p_line_rec                     line_rec := LINE_DEF) IS
  l_line_rec    line_rec := p_line_rec;
  l_log_id      PLS_INTEGER := Nvl(p_log_id, g_singleton_id);
BEGIN

  l_line_rec.do_close := FALSE;
  FOR i IN 1..p_line_lis.COUNT LOOP
    Put_Line(p_log_id       => l_log_id,
             p_line_text    => p_line_lis(i),
             p_line_rec     => l_line_rec);
  END LOOP;
  IF p_line_rec.do_close THEN
    Close_Log(l_log_id);
  END IF;

END Put_List;

/***************************************************************************************************

Close_Log: Close log by flushing buffer passing True for p_do_close

***************************************************************************************************/
PROCEDURE Close_Log(
            p_log_id                       PLS_INTEGER := NULL,     -- log id
            p_line_text                    VARCHAR2 := NULL,        -- line text to put
            p_line_rec                     line_rec := LINE_DEF) IS -- line record
  l_log_id                    PLS_INTEGER := Nvl(p_log_id, g_singleton_id);
BEGIN

  IF p_line_text IS  NOT NULL THEN
    Put_Line(p_log_id     => l_log_id,
             p_line_text  => p_line_text,
             p_line_rec   => p_line_rec);
  END IF;
  flush_Buf(g_log_lis(l_log_id), TRUE);

END Close_Log;

/***************************************************************************************************

get_Error_Log_Id: Construct a new log of default error config and return log id

***************************************************************************************************/
FUNCTION get_Error_Log_Id
            RETURN                         PLS_INTEGER IS
  l_error_config_key          log_configs.config_key%TYPE;
  l_log_id                    PLS_INTEGER;
BEGIN
  l_error_config_key := Log_Config.Get_Default_Error_Config;
  RETURN Construct(p_construct_rec => Con_Construct_Rec(
                             p_config_key => l_error_config_key));
END get_Error_Log_Id;

/***************************************************************************************************

Raise_Error: Raise an error, putting it to log if id passed, then calling Utils procedure to raise

***************************************************************************************************/
PROCEDURE Raise_Error(
            p_err_msg                      VARCHAR2,             -- error message
            p_log_id                       PLS_INTEGER := NULL,  -- log id
            p_line_rec                     line_rec := LINE_DEF, -- line record
            p_do_close                     BOOLEAN := TRUE) IS   -- True if to close log
  l_line_rec                     line_rec := p_line_rec;
  l_log_id                    PLS_INTEGER := p_log_id;
BEGIN

  IF l_log_id IS NULL THEN

    l_log_id := get_Error_Log_Id;
    
  END IF;
  l_line_rec.line.err_msg := p_err_msg;
  l_line_rec.line.line_type := LINE_TYPE_ERROR;
  l_line_rec.do_close := p_do_close;
  Put_Line(p_log_id       => l_log_id,
           p_line_text    => NULL,
           p_line_rec     => l_line_rec);
  Utils.Raise_Error(p_err_msg);

END Raise_Error;

/***************************************************************************************************

Write_Other_Error: Write the SQL error and backtrace to log, called from WHEN OTHERS

***************************************************************************************************/
PROCEDURE Write_Other_Error(
            p_log_id                       PLS_INTEGER := NULL,  -- log id
            p_line_text                    VARCHAR2 := NULL,     -- line text to put
            p_line_rec                     line_rec := LINE_DEF, -- line record
            p_do_close                     BOOLEAN := TRUE) IS   -- True if to close log
  l_line_rec                  line_rec := p_line_rec;
  l_log_id                    PLS_INTEGER := p_log_id;
BEGIN

  IF l_log_id IS NULL THEN

    l_log_id := get_Error_Log_Id;

  END IF;
  l_line_rec.do_close             := p_do_close;
  l_line_rec.line.line_type       := LINE_TYPE_ERROR;
  l_line_rec.line.err_num         := SQLCODE;
  l_line_rec.line.err_msg         := SQLERRM;
  l_line_rec.line.call_stack      := DBMS_Utility.Format_Call_Stack;
  l_line_rec.line.error_backtrace := DBMS_Utility.Format_Error_Backtrace;

  Put_Line(p_log_id     => l_log_id,
           p_line_text  => p_line_text,
           p_line_rec   => l_line_rec);

END Write_Other_Error;

/***************************************************************************************************

Delete_Log: Delete all logs matching either a single log id or a session id which may have multiple 
            logs. Exactly one parameter must be passed. This uses an autonomous transaction.

***************************************************************************************************/
PROCEDURE Delete_Log(
            p_log_id                       PLS_INTEGER := NULL, -- log id
            p_min_log_id                   PLS_INTEGER := 0, -- log id min
            p_session_id                   VARCHAR2 := NULL) IS -- session id
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

  IF p_log_id IS NULL AND p_session_id IS NOT NULL THEN

    DELETE log_lines WHERE log_id IN (
        SELECT id FROM log_headers WHERE session_id = Log_Set.SESSION_ID AND id > p_min_log_id
      );
    DELETE log_headers WHERE session_id = Log_Set.SESSION_ID AND id > p_min_log_id;
    g_singleton_id := NULL;

  ELSIF p_log_id IS NOT NULL AND p_session_id IS NULL THEN

    DELETE log_headers WHERE id = p_log_id;
    IF g_singleton_id = p_log_id THEN
      g_singleton_id := NULL;
    END IF;

  ELSE

    ROLLBACK;
    Raise_Error(p_err_msg => 'Delete_Log error: Exactly one of log id and session id must be passed');

  END IF;
  COMMIT;


END Delete_Log;

/***************************************************************************************************

Entry_Point: Function to be called to create a log at the start of an entry point API

***************************************************************************************************/
FUNCTION Entry_Point(
            p_plsql_unit                  VARCHAR2,         -- name of calling package
            p_api_nm                      VARCHAR2,         -- name of calling program unit
            p_config_key                  VARCHAR2,         -- config key
            p_text                        VARCHAR2 := NULL) -- text to append to initial line
            RETURN                        PLS_INTEGER IS    -- log id
  l_log_id             PLS_INTEGER := Log_Set.Construct(
    p_construct_rec => Log_Set.Con_Construct_Rec(p_config_key => p_config_key, 
                              p_plsql_unit => p_plsql_unit, 
                              p_api_nm     => p_api_nm),
    p_line_text     => 'Enter ' || p_api_nm || CASE WHEN p_text IS NOT NULL THEN ': ' || p_text END);
BEGIN
  RETURN l_log_id;
END Entry_Point;

/***************************************************************************************************

Exit_Point: Procedure to be called to close a log at the end of an entry point API

***************************************************************************************************/
PROCEDURE Exit_Point(
            p_log_id                      PLS_INTEGER,         -- log id
            p_text                        VARCHAR2 := NULL) IS -- text to append to exit line
BEGIN
  Log_Set.Close_Log(p_log_id    => p_log_id,
                    p_line_text => 'Exit' || CASE WHEN p_text IS NOT NULL THEN ': ' || p_text END);
END Exit_Point;

END Log_Set;
/
SHOW ERROR