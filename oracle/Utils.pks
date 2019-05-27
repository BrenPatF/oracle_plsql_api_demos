CREATE OR REPLACE PACKAGE Utils AUTHID CURRENT_USER AS
/***************************************************************************************************
Description: This package contains general utility procedures. It was published initially with two
             other utility packages for the articles linked in the link below:

                 Utils_TT:  Utility procedures for Brendan's TRAPIT API testing framework
                 Timer_Set: Code timing utility

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        08-May-2016 1.0   Initial for first article
Brendan Furey        21-May-2016 1.1   Replaced SYS.ODCI types with custom types L1_chr_arr etc.
Brendan Furey        24-Jun-2016 1.2   Row_To_List added
Brendan Furey        09-Jul-2016 1.3   Write_Log: added p_indent_level parameter
Brendan Furey        04-Aug-2016 1.4   Delete_File, Write_File added

***************************************************************************************************/

c_list_end_marker       CONSTANT VARCHAR2(30) := 'LIST_END_MARKER';
g_list_delimiter                 VARCHAR2(30) := '|';
c_time_fmt              CONSTANT VARCHAR2(30) := 'HH24:MI:SS';
c_datetime_fmt          CONSTANT VARCHAR2(30) := 'DD Mon RRRR ' || c_time_fmt;
c_fld_delim             CONSTANT VARCHAR2(30) := '  ';
Is_TT_Mode              CONSTANT BOOLEAN := Substr (SYS_Context ('userenv', 'client_info'), 1, 2) = 'TT';
c_session_id_if_TT               VARCHAR2(30);

FUNCTION Create_Log (p_description VARCHAR2 DEFAULT NULL) RETURN PLS_INTEGER;
PROCEDURE Clear_Log (p_log_header_id PLS_INTEGER DEFAULT 0);
PROCEDURE Reset_Log (p_log_header_id PLS_INTEGER DEFAULT 0);
PROCEDURE Write_Log (p_text             VARCHAR2,
                     p_indent_level     PLS_INTEGER DEFAULT 0,
                     p_group_text       VARCHAR2 DEFAULT NULL);
PROCEDURE Write_Other_Error (p_package VARCHAR2 DEFAULT NULL, p_proc VARCHAR2 DEFAULT NULL, p_group_text VARCHAR2 DEFAULT NULL);

FUNCTION Get_Seconds (p_interval INTERVAL DAY TO SECOND) RETURN NUMBER;

PROCEDURE Heading (p_head VARCHAR2, p_indent_level PLS_INTEGER DEFAULT 0, p_group_text VARCHAR2 DEFAULT NULL);

FUNCTION List_Delim (p_field_lis L1_chr_arr, p_delim VARCHAR2 DEFAULT g_list_delimiter) RETURN VARCHAR2;
FUNCTION List_Delim ( p_field1 VARCHAR2,
                      p_field2 VARCHAR2 DEFAULT c_list_end_marker, p_field3 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field4 VARCHAR2 DEFAULT c_list_end_marker, p_field5 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field6 VARCHAR2 DEFAULT c_list_end_marker, p_field7 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field8 VARCHAR2 DEFAULT c_list_end_marker, p_field9 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field10 VARCHAR2 DEFAULT c_list_end_marker, p_field11 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field12 VARCHAR2 DEFAULT c_list_end_marker, p_field13 VARCHAR2 DEFAULT c_list_end_marker,
                      p_field14 VARCHAR2 DEFAULT c_list_end_marker, p_field15 VARCHAR2 DEFAULT c_list_end_marker) RETURN VARCHAR2;

PROCEDURE Pr_List_As_Line (p_val_lis L1_chr_arr, p_len_lis L1_num_arr, p_indent_level PLS_INTEGER DEFAULT 0, p_save_line BOOLEAN DEFAULT FALSE);
PROCEDURE Reprint_Line;
PROCEDURE Col_Headers (p_val_lis L1_chr_arr, p_len_lis L1_num_arr, p_indent_level PLS_INTEGER DEFAULT 0);

FUNCTION Row_To_List (p_row VARCHAR2) RETURN L1_chr_arr;
FUNCTION Max_Len (p_lis L1_chr_arr) RETURN PLS_INTEGER;
FUNCTION Max_Len_2lis (p_2lis L2_chr_arr) RETURN L1_num_arr;

PROCEDURE Delete_File (p_file_name VARCHAR2);
PROCEDURE Write_File (p_file_name VARCHAR2, p_lines L1_chr_arr);

g_debug_level           PLS_INTEGER := 1;
g_line_size             PLS_INTEGER := 180;
g_group_text            VARCHAR2(30);
END Utils;
/
SHOW ERROR
CREATE OR REPLACE PUBLIC SYNONYM Utils FOR Utils
/
GRANT EXECUTE ON Utils TO PUBLIC
/
