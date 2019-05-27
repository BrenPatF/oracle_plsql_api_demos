BREAK ON id
COLUMN group_text FORMAT A20
COLUMN text FORMAT A4000
COLUMN "Time" FORMAT A8
SET LINES 4100
SET PAGES 10000
set heading off
SELECT line_text text
  FROM log_lines
 WHERE log_header_id = 0
 ORDER BY id
/
