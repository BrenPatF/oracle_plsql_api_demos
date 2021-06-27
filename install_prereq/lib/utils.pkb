CREATE OR REPLACE PACKAGE BODY Utils AS
/***************************************************************************************************
Name: utils.pkb                        Author: Brendan Furey                       Date: 26-May-2019

Package body component in the oracle_plsql_utils module. 

This module comprises a set of generic user-defined Oracle types and a PL/SQL package of functions
and procedures of general utility.

    GitHub: https://github.com/BrenPatF/oracle_plsql_utils

====================================================================================================
|  Package |  Notes                                                                                |
|==================================================================================================|
| *Utils*  |  General utility functions and procedures                                             |
====================================================================================================

This file has the Utils package body. See README for API specification, and the main_col_group.sql
script for simple examples of use.

This package runs with Invoker rights, not the default Definer rights, so that the dynamic SQL 
methods execute SQL using the rights of the calling schema, not the lib schema (if different).
***************************************************************************************************/

LINES                         CONSTANT VARCHAR2(1000) := '--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';
EQUALS                        CONSTANT VARCHAR2(1000) := '=======================================================================================================================================================================================================';
INPUT_DIR                     CONSTANT VARCHAR2(30) := 'INPUT_DIR';
FLD_DELIM                     CONSTANT VARCHAR2(30) := '  ';
CUSTOM_ERRNO                  CONSTANT PLS_INTEGER := -20000;

/***************************************************************************************************

Heading: Return a 2-element list of strings as a heading with double underlining

***************************************************************************************************/
FUNCTION Heading(
            p_head                         VARCHAR2,         -- heading string
            p_num_blanks_pre               PLS_INTEGER := 0, -- # blank lines before
            p_num_blanks_post              PLS_INTEGER := 0) -- # blank lines after
            RETURN                         L1_chr_arr IS     -- heading as 2-element list

  l_under       VARCHAR2(500) := Substr(EQUALS, 1, Length(p_head));
  l_ret_lis     L1_chr_arr := L1_chr_arr();

BEGIN

  l_ret_lis.EXTEND(p_num_blanks_pre + 2 + p_num_blanks_post);
  l_ret_lis(p_num_blanks_pre + 1) := p_head;
  l_ret_lis(p_num_blanks_pre + 2) := l_under;
  RETURN l_ret_lis;

END Heading;

/***************************************************************************************************

Col_Headers: Return a set of column headers, input as lists of values and length/justification's

***************************************************************************************************/
FUNCTION Col_Headers(
            p_value_lis                    chr_int_arr)  -- token, length list, with minus sigm meaning right-justify
            RETURN                         L1_chr_arr IS -- column headers as 2-element list
  l_line_lis    chr_int_arr := chr_int_arr();
  l_ret_lis     L1_chr_arr := L1_chr_arr();
BEGIN
  l_ret_lis.EXTEND(2);
  l_ret_lis(1) := List_To_Line(p_value_lis);

  l_line_lis.EXTEND(p_value_lis.COUNT);
  FOR i IN 1..p_value_lis.COUNT LOOP

    l_line_lis(i) := chr_int_rec(LINES, p_value_lis(i).int_value);

  END LOOP;
  l_ret_lis(2) := List_To_Line(l_line_lis);
  RETURN l_ret_lis;

END Col_Headers;

/***************************************************************************************************

List_To_Line: Return a list of strings as one line, saving for reprinting later if desired,
                 separating fields by a 2-space delim; second list is numbers for lengths, with
                 -ve/+ve sign denoting right/left-justify

***************************************************************************************************/
FUNCTION List_To_Line(
            p_value_lis                    chr_int_arr) -- token, length list, with minus sigm meaning right-justify
            RETURN                         VARCHAR2 IS  -- line
  l_line        VARCHAR2(32767);
  l_fld         VARCHAR2(32767);
  l_val         VARCHAR2(32767);
BEGIN

  FOR i IN 1..p_value_lis.COUNT LOOP
    l_val := Nvl(p_value_lis(i).chr_value, ' ');
    IF p_value_lis(i).int_value < 0 THEN
      l_fld := LPad(l_val, -p_value_lis(i).int_value);
    ELSE
      l_fld := RPad(l_val, p_value_lis(i).int_value);
    END IF;
    IF i = 1 THEN
      l_line := l_fld;
    ELSE
      l_line := l_line || FLD_DELIM || l_fld;
    END IF;

  END LOOP;
  RETURN l_line;

END List_To_Line;
/***************************************************************************************************

Join_Values: Return a delimited string for an input list of strings

***************************************************************************************************/
FUNCTION Join_Values(
            p_value_lis                    L1_chr_arr,        -- list of strings
            p_delim                        VARCHAR2 := DELIM) -- delimiter
            RETURN                         VARCHAR2 IS        -- delimited string

  l_str         VARCHAR2(32767) := p_value_lis(1);

BEGIN

  FOR i IN 2..p_value_lis.COUNT LOOP

    l_str := l_str || p_delim || p_value_lis(i);

  END LOOP;
  RETURN l_str;

END Join_Values;

/***************************************************************************************************

Join_Values: Return a delimited string for an input set of from 1 to 17 strings

***************************************************************************************************/
FUNCTION Join_Values(
            p_value1                       VARCHAR2, -- input string, first is required, others passed as needed
            p_value2                       VARCHAR2 := PRMS_END, p_value3  VARCHAR2 := PRMS_END,
            p_value4                       VARCHAR2 := PRMS_END, p_value5  VARCHAR2 := PRMS_END,
            p_value6                       VARCHAR2 := PRMS_END, p_value7  VARCHAR2 := PRMS_END,
            p_value8                       VARCHAR2 := PRMS_END, p_value9  VARCHAR2 := PRMS_END,
            p_value10                      VARCHAR2 := PRMS_END, p_value11 VARCHAR2 := PRMS_END,
            p_value12                      VARCHAR2 := PRMS_END, p_value13 VARCHAR2 := PRMS_END,
            p_value14                      VARCHAR2 := PRMS_END, p_value15 VARCHAR2 := PRMS_END,
            p_value16                      VARCHAR2 := PRMS_END, p_value17 VARCHAR2 := PRMS_END,
            p_delim                        VARCHAR2 := DELIM) -- delimiter
            RETURN                         VARCHAR2 IS        -- delimited string

  l_list   L1_chr_arr := L1_chr_arr(p_value2, p_value3, p_value4, p_value5, p_value6, p_value7,
              p_value8, p_value9, p_value10, p_value11, p_value12, p_value13, p_value14, p_value15,
              p_value16, p_value17);
  l_str    VARCHAR2(32767) := p_value1;

BEGIN

  FOR i IN 1..l_list.COUNT LOOP

    IF l_list(i) = PRMS_END THEN
      EXIT;
    END IF;
    l_str := l_str || p_delim || l_list(i);

  END LOOP;
  RETURN l_str;

END Join_Values;

/***************************************************************************************************

Split_Values: Returns a list of tokens from a delimited string

***************************************************************************************************/
FUNCTION Split_Values(
            p_string                       VARCHAR2,          -- delimited string
            p_delim                        VARCHAR2 := DELIM) -- delimiteriter
            RETURN                         L1_chr_arr IS      -- list of tokens
  l_start_pos   PLS_INTEGER := 1;
  l_end_pos     PLS_INTEGER;
  l_arr_index   PLS_INTEGER := 1;
  l_arr         L1_chr_arr := L1_chr_arr();
  l_row         VARCHAR2(32767) := p_string || p_delim;
BEGIN

  WHILE l_start_pos <= Length(l_row) LOOP

    l_end_pos := Instr(l_row, p_delim, 1, l_arr_index) - 1;
    IF l_end_pos < 0 THEN
      l_end_pos := Length(l_row);
    END IF;
    l_arr.EXTEND;
    l_arr(l_arr.COUNT) := Substr(l_row, l_start_pos, l_end_pos - l_start_pos + 1);
    l_start_pos := l_end_pos + 2;
    l_arr_index := l_arr_index + 1;
  END LOOP;

  RETURN l_arr;

END Split_Values;

/***************************************************************************************************

View_To_List: Run a query dynamically on a view (or table) and return result set as array of strings

***************************************************************************************************/
FUNCTION View_To_List(         
            p_view_name                    VARCHAR2,          -- name of view
            p_sel_value_lis                L1_chr_arr,        -- list of fields to select
            p_where                        VARCHAR2 := NULL,  -- optional where clause
            p_order_by                     VARCHAR2 := '1',   -- optional order by
            p_delim                        VARCHAR2 := DELIM) -- optional delimiter
            RETURN                         L1_chr_arr IS      -- list of delimited result records

  l_cur            SYS_REFCURSOR;
  l_sql_txt        VARCHAR2(32767) := 'SELECT Utils.Join_Values(L1_chr_arr(';
  l_result_lis     L1_chr_arr;

BEGIN

  FOR i IN 1..p_sel_value_lis.COUNT LOOP

    l_sql_txt := l_sql_txt || p_sel_value_lis(i) || ',';

  END LOOP;

  l_sql_txt := RTrim(l_sql_txt, ',') || '), ''' || p_delim || ''') FROM ' || p_view_name || 
               ' WHERE ' || Nvl(p_where, '1=1 ') || 'ORDER BY ' || p_order_by;

  OPEN l_cur FOR l_sql_txt;

  FETCH l_cur BULK COLLECT
    INTO l_result_lis;

  CLOSE l_cur;
  RETURN l_result_lis;

END View_To_List;

/***************************************************************************************************

Cursor_To_List: Takes an open ref cursor, reads from it and returns the output records as a list of
                delimited strings. If a filter is passed, then only strings matching it (regular
                expression - RegExp_Like) are returned. Cursor is closed at the end

***************************************************************************************************/
FUNCTION Cursor_To_List(  
            x_csr                   IN OUT SYS_REFCURSOR,     -- (open) ref cursor
            p_filter                       VARCHAR2 := NULL,  -- filter string
            p_delim                        VARCHAR2 := DELIM) -- filter string
            RETURN                         L1_chr_arr IS      -- list of delimited result records

  c_chr_type    CONSTANT PLS_INTEGER := 1; --DBMS_Types.TYPECODE_* do not seem to quite work
  c_num_type    CONSTANT PLS_INTEGER := 2;
  c_dat_type    CONSTANT PLS_INTEGER := 12;
  c_stp_type    CONSTANT PLS_INTEGER := 180;
  l_csr_id      PLS_INTEGER;
  l_n_cols      PLS_INTEGER;
  l_desctab     DBMS_SQL.DESC_TAB;
  l_chr_val     VARCHAR2(4000);
  l_num_val     NUMBER;
  l_dat_val     DATE;
  l_stp_val     TIMESTAMP;
  l_val_lis     L1_chr_arr;
  l_res_lis     L1_chr_arr := L1_chr_arr();
  l_rec         VARCHAR2(4000);

BEGIN

  l_csr_id := DBMS_SQL.To_Cursor_Number(x_csr);
  DBMS_SQL.Describe_Columns(l_csr_id, l_n_cols, l_desctab);

  FOR i IN 1..l_n_cols LOOP

    CASE l_desctab(i).col_type

      WHEN c_chr_type THEN
        DBMS_SQL.Define_Column(l_csr_id, i, l_chr_val, 4000);
      WHEN c_num_type THEN
        DBMS_SQL.Define_Column(l_csr_id, i, l_num_val);
      WHEN c_dat_type THEN
        DBMS_SQL.Define_Column(l_csr_id, i, l_dat_val);
      WHEN c_stp_type THEN
         DBMS_SQL.Define_Column(l_csr_id, i, l_stp_val);
     ELSE
        Raise_Error('Cursor_to_Array: Col type ' || l_desctab(i).col_type || 
          ' not accounted for!');

    END CASE;

  END LOOP;

  WHILE DBMS_SQL.Fetch_Rows(l_csr_id) > 0 LOOP

    l_val_lis := L1_chr_arr();
    l_val_lis.EXTEND(l_n_cols);
    FOR i IN 1 .. l_n_cols LOOP

      CASE l_desctab(i).col_type

        WHEN c_chr_type THEN
          DBMS_SQL.Column_Value(l_csr_id, i, l_chr_val);
          l_val_lis(i) := l_chr_val;
        WHEN c_num_type THEN
          DBMS_SQL.Column_Value(l_csr_id, i, l_num_val);
          l_val_lis(i) := l_num_val;
        WHEN c_dat_type THEN
          DBMS_SQL.Column_Value(l_csr_id, i, l_dat_val);
          l_val_lis(i) := l_dat_val;
        WHEN c_stp_type THEN
          DBMS_SQL.Column_Value(l_csr_id, i, l_stp_val);
          l_val_lis(i) := l_stp_val;

      END CASE;

    END LOOP;

    l_rec := Utils.Join_Values(p_value_lis => l_val_lis, p_delim => p_delim);
    IF p_filter IS NULL OR RegExp_Like(l_rec, p_filter) THEN
      l_res_lis.EXTEND;
      l_res_lis (l_res_lis.COUNT) := l_rec;
    END IF;

  END LOOP;

  DBMS_SQL.Close_Cursor (l_csr_id);
  RETURN l_res_lis;


END Cursor_To_List;

/***************************************************************************************************

IntervalDS_To_Seconds: Simple function to get the seconds as a number from an interval

***************************************************************************************************/
FUNCTION IntervalDS_To_Seconds(
            p_interval                     INTERVAL DAY TO SECOND) -- time interval
            RETURN                         NUMBER IS               -- time in seconds
BEGIN

  RETURN EXTRACT(SECOND FROM p_interval) + 60 * EXTRACT(MINUTE FROM p_interval) + 3600 * EXTRACT(HOUR FROM p_interval);

END IntervalDS_To_Seconds;

/***************************************************************************************************

Sleep: Custom sleep for testing, with CPU content, using DBMS_Lock.Sleep for the non-CPU part

***************************************************************************************************/
PROCEDURE Sleep(
            p_ela_seconds                  NUMBER,           -- elapsed time to sleep
            p_fraction_CPU                 NUMBER := 0.5) IS -- fraction of elapsed time to use CPU
  l_ela_start TIMESTAMP := SYSTIMESTAMP;
BEGIN

  WHILE SYSTIMESTAMP < l_ela_start + NumToDSInterval(p_fraction_CPU * p_ela_seconds, 'second') LOOP

    NULL;

  END LOOP;
  DBMS_Lock.Sleep((1 - p_fraction_CPU) * p_ela_seconds);

END Sleep;
/***************************************************************************************************

Raise_Error: Centralise RAISE_APPLICATION_ERROR, using just one error number

***************************************************************************************************/
PROCEDURE Raise_Error(
            p_message                      VARCHAR2) IS -- error message
BEGIN

  RAISE_APPLICATION_ERROR(CUSTOM_ERRNO, p_message);

END Raise_Error;

/***************************************************************************************************

W: Overloaded procedure to write a line, or an array of lines, to output using DBMS_Output;
  to use a logging framework, replace the Put_Line calls with your custom logging calls

***************************************************************************************************/
PROCEDURE W(p_line                         VARCHAR2) IS -- line of text to write
BEGIN
  DBMS_Output.Put_line(p_line);
END W;

PROCEDURE W(p_line_lis                     L1_chr_arr) IS -- array of lines of text to write
BEGIN
  FOR i IN 1..p_line_lis.COUNT LOOP
    DBMS_Output.Put_line(p_line_lis(i));
  END LOOP;
END W;

/***************************************************************************************************

Delete_File: Delete OS file if present (used in ut)

***************************************************************************************************/
PROCEDURE Delete_File(
            p_file_name                    VARCHAR2) IS -- OS file name
BEGIN

  UTL_File.FRemove(INPUT_DIR, p_file_name);

END Delete_File;

/***************************************************************************************************

Write_File: Open an OS file and write an input list of lines to it, then close it (used in ut)

***************************************************************************************************/
PROCEDURE Write_File(
            p_file_name                    VARCHAR2,      -- OS file name
            p_line_lis                     L1_chr_arr) IS -- list of lines to write
  l_file_ptr            UTL_FILE.File_Type;
BEGIN

  l_file_ptr := UTL_File.FOpen(INPUT_DIR, p_file_name, 'W', 32767);
  IF p_line_lis IS NOT NULL THEN

    FOR i IN 1..p_line_lis.COUNT LOOP

      UTL_File.Put_Line(l_file_ptr, p_line_lis(i));

    END LOOP;

  END IF;
  UTL_File.FClose(l_file_ptr);

END Write_File;

/***************************************************************************************************

Read_File: Open an OS file and read lines into a list, then close it

***************************************************************************************************/
FUNCTION Read_File(
            p_file_name                    VARCHAR2)
            RETURN                         L1_chr_arr IS
  l_file_ptr            UTL_FILE.File_Type;
  l_line                VARCHAR2(32767);
  l_lines               L1_chr_arr := L1_chr_arr();
  i PLS_INTEGER := 0;
BEGIN

  l_file_ptr := UTL_File.FOpen(INPUT_DIR, p_file_name, 'R', 32767);

  LOOP
    i := i + 1;
    UTL_File.Get_Line(l_file_ptr, l_line);
    l_lines.EXTEND;
    l_lines(l_lines.COUNT) := l_line;

  END LOOP;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    UTL_File.FClose(l_file_ptr);
    RETURN l_lines;

END Read_File;

/***************************************************************************************************

get_SQL_Id: Given a marker string to match against in v$sql get the sql_id

***************************************************************************************************/
FUNCTION get_SQL_Id(
            p_sql_marker                 VARCHAR2)          -- marker string
                                         RETURN VARCHAR2 IS -- sql id
  l_sql_id VARCHAR2(60);
BEGIN

  SELECT Max(sql_id) KEEP (DENSE_RANK LAST ORDER BY last_load_time)
    INTO l_sql_id
    FROM v$sql
   WHERE sql_text LIKE '% ' || p_sql_marker || ' %' 
     AND UPPER(sql_text) NOT LIKE '%SQL_TEXT LIKE%' -- excludes this query
     AND plan_hash_value != 0;                      -- excludes PL/SQL blocks

  RETURN l_sql_id;

END get_SQL_Id;

/***************************************************************************************************

Get_XPlan: Given a marker string to match against in v$sql extract the execution plan via 
           DBMA_XPlan and return as a list of strings

***************************************************************************************************/
FUNCTION Get_XPlan(
            p_sql_marker                   VARCHAR2,              -- SQL marker string (include in the SQL)
            p_add_outline                  BOOLEAN DEFAULT FALSE) -- repeat the plan with outline added
            RETURN                         L1_chr_arr IS          -- list of XPlan lines

  l_sql_id      VARCHAR2(60) := get_SQL_Id (p_sql_marker);
  l_xplan_lis   L1_chr_arr := L1_chr_arr();

  PROCEDURE Ins_Plan(p_type VARCHAR2) IS
  BEGIN

    FOR rec IN (
        SELECT plan_table_output
          FROM TABLE(DBMS_XPlan.Display_Cursor(l_sql_id, NULL, p_type))
               ) LOOP
      l_xplan_lis.EXTEND;
      l_xplan_lis(l_xplan_lis.COUNT) := rec.plan_table_output;

    END LOOP;

  END Ins_Plan;

BEGIN

  Ins_Plan ('ALLSTATS LAST');
  IF p_add_outline THEN

    Ins_Plan ('OUTLINE LAST');

  END IF;

  RETURN l_xplan_lis;

END Get_XPlan;

END Utils;
/
SHOW ERROR