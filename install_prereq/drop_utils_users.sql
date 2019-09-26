@InitSpool drop_utils_users
DEFINE LIB_USER=lib
DEFINE APP_USER=app

PROMPT Drop &LIB_USER and &APP_USER
DROP USER &LIB_USER CASCADE
/
DROP USER &APP_USER CASCADE
/
PROMPT Drop directory input_dir
DROP DIRECTORY input_dir
/
@EndSpool