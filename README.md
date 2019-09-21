# Oracle PL/SQL API Demos
Module demonstrating instrumentation and logging, code timing and unit testing of Oracle PL/SQL APIs.

PL/SQL procedures were written against Oracle's HR demo schema to represent the different kinds of API across two axes: Setter/Getter and Real Time/Batch.

Mode          | Setter Example (S)          | Getter Example (G)
--------------|-----------------------------|----------------------------------
Real Time (R) | Web service saving          | Web service getting by ref cursor
Batch (B)     | Batch loading of flat files | Views

The PL/SQL procedures and view were written originally to demonstrate unit testing, and are as follows:

- RS: Emp_WS.Save_Emps - Save a list of new employees to database, returning list of ids with Julian dates; logging errors to err$ table
- RG: Emp_WS.Get_Dept_Emps - For given department id, return department and employee details including salary ratios, excluding employees with job 'AD_ASST', and returning none if global salary total < 1600, via ref cursor
- BS: Emp_Batch.Load_Emps - Load new/updated employees from file via external table
- BG: hr_test_view_v - View returning department and employee details including salary ratios, excluding employees with job 'AD_ASST', and returning none if global salary total < 1600

Each of these is unit tested, as described below, and in addition there is a driver script, api_driver.sql, that calls each of them and lists the results of logging and code timing.

## Unit Testing
The PL/SQL APIs are tested using the Math Function Unit Testing design pattern, with test results in HTML and text format included. The design pattern is based on the idea that all API testing programs can follow a universal design pattern, using the concept of a �pure� function as a wrapper to manage the �impurity� inherent in database APIs. I explained the concepts involved in a presentation at the Oracle User Group Ireland Conference in March 2018:

<a href="https://www.slideshare.net/brendanfurey7/database-api-viewed-as-a-mathematical-function-insights-into-testing" target="_blank">The Database API Viewed As A Mathematical Function: Insights into Testing</a>

In this data-driven design pattern a driver program reads a set of scenarios from a JSON file, and loops over the scenarios calling the wrapper function with the scenario as input and obtaining the results as the return value. Utility functions from the Trapit module convert the input JSON into PL/SQL arrays, and, conversely, the output arrays into JSON text that is written to an output JSON file. This latter file contains all the input values and output values (expected and actual), as well as metadata describing the input and output groups. A separate nodejs module can be run to process the output files and create HTML files showing the results: Each unit test (say `pkg.prc`) has its own root page `pkg.prc.html` with links to a page for each scenario, located within a subfolder `pkg.prc`. Here, they have been copied into a subfolder test_output, as follows:

- tt_emp_batch.load_emps
- tt_emp_ws.get_dept_emps
- tt_emp_ws.save_emps
- tt_view_drivers.hr_test_view_v

Where the actual output record matches expected, just one is represented, while if the actual differs it is listed below the expected and with background colour red. The employee group in scenario 4 of tt_emp_ws.save_emps has two records deliberately not matching, the first by changing the expected salary and the second by adding a duplicate expected record.

Each of the `pkg.prc` subfolders also includes a JSON Structure Diagram, `pkg.prc.png`, showing the input/output structure of the pure unit test wrapper function.

Here, for example, is the unit test summary (in text version) for the first test:

    Unit Test Report: TT_Emp_WS.Save_Emps
    =====================================
    
       SCENARIO 1: 1 valid record : 0 failed of 3: SUCCESS
       SCENARIO 2: 1 invalid job id : 0 failed of 3: SUCCESS
       SCENARIO 3: 1 invalid number : 0 failed of 3: SUCCESS
       SCENARIO 4: 2 valid records, 1 invalid job id (2 deliberate errors) : 1 failed of 3: FAILURE
    
    Test scenarios: 1 failed of 4: FAILURE
    ======================================

## Logging and Instrumentation
Program instrumentation means including lines of code to monitor the execution of a program, such as tracing lines covered, numbers of records processed, and timing information. Logging means storing such information, in database tables or elsewhere.

The Log_Set module allows for logging of various data in a lines table linked to a header for a given log, with the logging level configurable at runtime. The module also uses Oracle's DBMS_Application_Info API to allow for logging in memory only with information accessible via the V$SESSION and V$SESSION_LONGOPS views.

The two web service-type APIs, Emp_WS.Save_Emps and Emp_WS.Get_Dept_Emps, use a configuration that logs only via DBMS_Application_Info, while the batch API, Emp_Batch.Load_Emps, also logs to the tables. The view of course does not do any logging itself but calling programs can log the results of querying it.

The driver script api_driver.sql calls all four of the demo APIs and performs its own logging of the calls and the results returned, including the DBMS_Application_Info on exit. The driver logs using a special DEBUG configuration where the log is constructed implicitly by the first Put, and there is no need to pass a log identifier when putting (so debug lines can be easily added in any called package). At the end of the script queries are run that list the contents of the logs created during the session in creation order, first normal logs, then a listing for error logs (of which one is created by deliberately raising an exception handled in WHEN OTHERS).

Here, for example, is the text logged by the driver script for the first call:

    Call Emp_WS.Save_Emps to save a list of employees passed...
    ===========================================================
    DBMS_Application_Info: Module = EMP_WS: Log id 127
    ...................... Action = Log id 127 closed at 12-Sep-2019 06:20:2
    ...................... Client Info = Exit: Save_Emps, 2 inserted
    Print the records returned...
    =============================
    1862 - ONE THOUSAND EIGHT HUNDRED SIXTY-TWO
    1863 - ONE THOUSAND EIGHT HUNDRED SIXTY-THREE

## Code Timing
The code timing module Timer_Set is used by the driver script, api_driver.sql, to time the various calls, and at the end of the main block the results are logged using Log_Set. The timing results, for illustration are listed below:

    Timer Set: api_driver, Constructed at 12 Sep 2019 06:20:28, written at 06:20:29
    ===============================================================================
    Timer             Elapsed         CPU       Calls       Ela/Call       CPU/Call
    -------------  ----------  ----------  ----------  -------------  -------------
    Save_Emps            0.00        0.00           1        0.00100        0.00000
    Get_Dept_Emps        0.00        0.00           1        0.00100        0.00000
    Write_File           0.00        0.02           1        0.00300        0.02000
    Load_Emps            0.22        0.15           1        0.22200        0.15000
    Delete_File          0.00        0.00           1        0.00200        0.00000
    View_To_List         0.00        0.00           1        0.00200        0.00000
    (Other)              0.00        0.00           1        0.00000        0.00000
    -------------  ----------  ----------  ----------  -------------  -------------
    Total                0.23        0.17           7        0.03300        0.02429
    -------------  ----------  ----------  ----------  -------------  -------------
    [Timer timed (per call in ms): Elapsed: 0.00794, CPU: 0.00873]

## Installation
The database installation requires a minimum Oracle version of 12.2, with Oracle's HR demo schema installed:

<a href="https://docs.oracle.com/cd/E11882_01/server.112/e10831/installation.htm#COMSC001" target="_blank">Oracle Database Sample Schemas</a>

The demo install depends on the pre-requisite modules Utils, Log_Set, and Timer_Set, and `lib` and `app` schemas refer to the schemas in which Utils and examples are installed, respectively.

### Install 1: Install Utils module
#### [Schema: lib; Folder: (Utils) lib]
- Download and install the Utils module:
[Utils on GitHub](https://github.com/BrenPatF/oracle_plsql_utils)

The Utils install includes a step to install the separate Trapit PL/SQL unit testing module, and this step is required for the unit testing part of the current module.

### Install 2: Install Log_Set module
#### [Schema: lib; Folder: (Log_Set) lib]
- Download and install the Log_Set module:
[Log_Set on GitHub](https://github.com/BrenPatF/log_set_oracle)

### Install 3: Install Timer_Set module
#### [Schema: lib; Folder: (Timer_Set) lib]
- Download and install the Timer_Set module:
[Timer_Set on GitHub](https://github.com/BrenPatF/timer_set_oracle)

### Install 4: Create Oracle PL/SQL API Demos components
- Copy the following files from the root folder to the server folder pointed to by the Oracle directory INPUT_DIR:
    - tt_emp_ws.save_emps_inp.json
    - tt_emp_ws.get_dept_emps_inp.json
    - tt_emp_batch.load_emps_inp.json
    - tt_view_drivers.hr_test_view_v_inp.json

#### [Schema: lib; Folder: lib]
- Run script from slqplus:
```
SQL> @install_jobs app
```
#### [Schema: hr; Folder: hr]
- Run script from slqplus:
```
SQL> @install_hr app
```
#### [Schema: app; Folder: app]
- Run script from slqplus:
```
SQL> @install_api_demos lib
```

## Running Driver Script and Unit Tests
### Running driver script
#### [Schema: app; Folder: app]
- Run script from slqplus:
```
SQL> @api_driver
```
The output is in api_driver.log

### Running unit tests
#### [Schema: app; Folder: app]
- Run script from slqplus:
```
SQL> @r_tests
```
Testing is data-driven from the input JSON objects that are loaded from files into the table tt_units (at install time), and produces JSON output files in the INPUT_DIR folder, that contain arrays of expected and actual records by group and scenario. These files are:

- tt_emp_batch.load_emps_out.json
- tt_emp_ws.get_dept_emps_out.json
- tt_emp_ws.save_emps_out.json
- tt_view_drivers.hr_test_view_v_out.json

The output files are processed by a nodejs program that has to be installed separately, from the `npm` nodejs repository, as described in the Trapit install (from the Utils `Install 1` above). The nodejs program produces listings of the results in HTML and/or text format, and result files are included in the subfolders below test_output. To run the processor (in Windows), open a DOS or Powershell window in the trapit package folder after placing the output JSON files in the subfolder ./examples/externals and run:

```
$ node ./examples/externals/test-externals
```

## Operating System/Oracle Versions
### Windows
Tested on Windows 10, should be OS-independent
### Oracle
- Tested on Oracle Database Version 18.3.0.0.0 (minimum required: 12.2)

## See also
- [Utils - Oracle PL/SQL general utilities module](https://github.com/BrenPatF/oracle_plsql_utils)
- [Trapit - Oracle PL/SQL unit testing module](https://github.com/BrenPatF/trapit_oracle_tester)
- [Log_Set - Oracle logging module](https://github.com/BrenPatF/log_set_oracle)
- [Timer_Set - Oracle PL/SQL code timing module](https://github.com/BrenPatF/timer_set_oracle)
- [Trapit - nodejs unit test processing package](https://github.com/BrenPatF/trapit_nodejs_tester)

## License
MIT