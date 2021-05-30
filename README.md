# Oracle PL/SQL API Demos
<img src="mountains.png">
Module demonstrating instrumentation and logging, code timing and unit testing of Oracle PL/SQL APIs.

:outbox_tray: :inbox_tray:

PL/SQL procedures were written against Oracle's HR demo schema to represent the different kinds of API across two axes: Setter/Getter and Real Time/Batch.

Mode          | Setter Example (S)          | Getter Example (G)
--------------|-----------------------------|----------------------------------
Real Time (R) | Web service saving          | Web service getting by ref cursor
Batch (B)     | Batch loading of flat files | View

The PL/SQL procedures and view were written originally to demonstrate unit testing, and are as follows:

- RS: Emp_WS.Save_Emps - Save a list of new employees to database, returning list of ids with Julian dates; logging errors to err$ table
- RG: Emp_WS.Get_Dept_Emps - For given department id, return department and employee details including salary ratios, excluding employees with job 'AD_ASST', and returning none if global salary total < 1600, via ref cursor
- BS: Emp_Batch.Load_Emps - Load new/updated employees from file via external table
- BG: hr_test_view_v - View returning department and employee details including salary ratios, excluding employees with job 'AD_ASST', and returning none if global salary total < 1600

Each of these is unit tested, as described below, and in addition there is a driver script, api_driver.sql, that calls each of them and lists the results of logging and code timing.

I presented on <a href="https://www.slideshare.net/brendanfurey7/clean-coding-in-plsql-and-sql" target="_blank" rel="noopener noreferrer">Writing Clean Code in PL/SQL and SQL</a> at the Ireland Oracle User Group Conference on 4 April 2019 in Dublin. The modules demonstrated here are written in the style recommended in the presentation where, in particular: 

- 'functional' code is preferred
- object-oriented code is used only where necessary, using a package record array approach, rather than type bodies
- record types, defaults and overloading used extensively to provide clean API interfaces 

## In this README...
- [Screen Recordings on this Module](https://github.com/BrenPatF/oracle_plsql_api_demos#screen-recordings-on-this-module)
- [Unit Testing](https://github.com/BrenPatF/oracle_plsql_api_demos#unit-testing)
- [Logging and Instrumentation](https://github.com/BrenPatF/oracle_plsql_api_demos#logging-and-instrumentation)
- [Code Timing](https://github.com/BrenPatF/oracle_plsql_api_demos#code-timing)
- [Functional PL/SQL](https://github.com/BrenPatF/oracle_plsql_api_demos#functional-plsql)
- [Installation](https://github.com/BrenPatF/oracle_plsql_api_demos#Installation)
- [Running Driver Script and Unit Tests](https://github.com/BrenPatF/oracle_plsql_api_demos#running-driver-script-and-unit-tests)
- [Operating System/Oracle Versions](https://github.com/BrenPatF/oracle_plsql_api_demos#operating-systemoracle-versions)

## Screen Recordings on this Module
- [In this README...](https://github.com/BrenPatF/oracle_plsql_api_demos#in-this-readme)

I initially made a series of screen recordings that are available at the links below, and later condensed each recording to a length that would upload directly to Twitter, i.e. less than 140 seconds. You can find the [Twitter thread here](https://twitter.com/BrenPatF/status/1195226809987674113). Both sets of recordings are also available in the recordings subfolder of the repository. The links below are to the initial, longer set of recordings.

### 1 Overview (6 recordings – 48m)
- [1.1 Introduction (5m)](https://reccloud.com/u/5usavxh)
- [1.2 Unit testing (13m)](https://reccloud.com/u/mkgxioc)
- [1.3 Logging and instrumentation (8m)](https://reccloud.com/u/pwaretg)
- [1.4 Code timing (6m)](https://reccloud.com/u/hzi79ra)
- [1.5 Functional PL/SQL I - pure functions; record types; separation of pure and impure (8m)](https://reccloud.com/u/jieo803)
- [1.6 Functional PL/SQL II - refactoring for purity (8m)](https://reccloud.com/u/y364pek)

### 2 Prerequisite Tools (1 recording – 3m)
- [2.1 Prerequisite tools (3m)](https://reccloud.com/u/7czksex)

### 3 Installation (3 recordings – 15m)
- [3.1 Clone git repository (2m)](https://reccloud.com/u/m6pvgyr)
- [3.2 Install prerequisite modules (7m)](https://reccloud.com/u/i8h29jn)
- [3.3 Install API demo components (6m)](https://reccloud.com/u/ec1amfv)

### 4 Running the scripts (4 recordings – 30m)
- [4.1 Run unit tests (8m)](https://reccloud.com/u/3lsih2r)
- [4.2 Review test results (7m)](https://reccloud.com/u/tm3hj8k)
- [4.3 Run API driver (8m)](https://reccloud.com/u/bcrs10p)
- [4.4 Review API driver output (7m)](https://reccloud.com/u/tz9ola1)

## Unit Testing
- [&uarr; In this README...](https://github.com/BrenPatF/oracle_plsql_api_demos#in-this-readme)
- [Unit Testing Process](https://github.com/BrenPatF/oracle_plsql_api_demos#unit-testing-process)
- [Wrapper Function](https://github.com/BrenPatF/oracle_plsql_api_demos#wrapper-function)
- [Unit Test Scenarios](https://github.com/BrenPatF/oracle_plsql_api_demos#unit-test-scenarios)

The PL/SQL APIs are tested using the Math Function Unit Testing design pattern, with test results in HTML and text format included. The design pattern is based on the idea that all API testing programs can follow a universal design pattern, using the concept of a ‘pure’ function as a wrapper to manage the ‘impurity’ inherent in database APIs. I explained the concepts involved in a presentation at the Ireland Oracle User Group Conference in March 2018:

- <a href="https://www.slideshare.net/brendanfurey7/database-api-viewed-as-a-mathematical-function-insights-into-testing" target="_blank">The Database API Viewed As A Mathematical Function: Insights into Testing</a>

I later named the approach 'The Math Function Unit Testing design pattern':
- [The Math Function Unit Testing design pattern, implemented in nodejs](https://github.com/BrenPatF/trapit_nodejs_tester)

I went on to implement a framework for applying the Math Function Unit Testing design pattern in Oracle, described here: 

- [Trapit - Oracle PL/SQL unit testing module](https://github.com/BrenPatF/trapit_oracle_tester).

This section describes how the unit testing process works in general, while detailed descriptions for each unit test program are provided in separate READMEs:

- [Unit Testing for API: Emp_Batch.Load_Emps](https://github.com/BrenPatF/oracle_plsql_api_demos/blob/master/testing/load_emps/README.md)
- [Unit Testing for API: Emp_WS.Get_Dept_Emps](https://github.com/BrenPatF/oracle_plsql_api_demos/blob/master/testing/get_dept_emps/README.md)
- [Unit Testing for API: Emp_WS.Save_Emps](https://github.com/BrenPatF/oracle_plsql_api_demos/blob/master/testing/save_emps/README.md)
- [Unit Testing for API: HR_Test_View_V](https://github.com/BrenPatF/oracle_plsql_api_demos/blob/master/testing/hr_test_view_v/README.md)

The unit test driver script, which causes all four unit test programs to be executed, may be run from the Oracle app subfolder:

```sql
SQL> @r_tests
```

The output files are processed by a nodejs program that has to be installed separately from the `npm` nodejs repository, as described in the Trapit install in `Installation` below. To run the processor, open a powershell window in the npm trapit package folder after placing the output JSON files, *_out.json, in the subfolder ./examples/externals and run:

```
$ node ./examples/externals/test-externals
```

This creates, or updates, subfolders with the formatted results output files. The three testing steps can easily be automated in Powershell (or Unix bash).

Unit testing artefacts are placed in folders by API, `api`, under a `testing` folder:

- testing
   - `api`
      - input - input JSON file, with CSV files and simple powershell script to create a template for it
      - output - output JSON file and results folder:
         - `unit test title` - results files in HTML format and text format

### Unit Testing Process
- [&uarr; Unit Testing](https://github.com/BrenPatF/oracle_plsql_api_demos#unit-testing)

In the Math Function Unit Testing design pattern, a 'pure' wrapper function is constructed that takes all inputs as a parameter, calls the unit under test, and returns the outputs as a single complex value. The driving unit test program is centralized in a library package that calls the specific wrapper function using dynamic SQL (in languages such as Javascript the wrapper would be a callback function), within a loop over scenario records read from a JSON file. The driver writes an output file that contains arrays of expected and actual records by group and scenario in a JSON format. This file is processed by a nodejs program that produces listings of the results in HTML and/or text format.
<div>
<img src="testing/Oracle PLSQL API Demos - DFD.png" text-align="center" display="inline-block">
</div>

The base procedure/view, the `unit under test`, has a corresponding unit test wrapper function, with both in the app schema/folder. 
- Base procedure/view: Unit under test, a view or package procedure in this demo, eg Emp_WS.Save_Emps
- Wrapper function: Unit test wrapper function, eg TT_Emp_WS.Purely_Wrap_Save_Emps

The input JSON file is created by the developer and placed in the Oracle directory `INPUT_DIR`, where the output file is also written. They have been copied here to the testing\\`api` folders:
- Input JSON: input\\`tt_pkg`.purely_wrap_`api`_inp.json 
- Output JSON: output\\`tt_pkg`.purely_wrap_`api`_out.json

An easy way to generate a starting point for the input JSON file is to use a powershell utility [Powershell Utilites module](https://github.com/BrenPatF/powershell_utils) to generate a template file with a single scenario with placeholder records from simple CSV files. The files for the demo examples are in folders testing\\`api`\input:
- Input CSV: purely_wrap_`api`_inp.csv
- Output CSV: purely_wrap_`api`_out.csv
- Powershell script: purely_wrap_`api`.ps1
- Template JSON: purely_wrap_`api`_temp.json

The results folders generated by the nodejs program have been copied to the testing\\`api`\output folders:
- Results folder: Eg testing\save_emps\output\oracle-pl_sql-api-demos_-tt_emp_ws.save_emps

### Wrapper Function
- [&uarr; Unit Testing](https://github.com/BrenPatF/oracle_plsql_api_demos#unit-testing)
- [Wrapper Function Signature Diagram](https://github.com/BrenPatF/oracle_plsql_api_demos#wrapper-function-signature-diagram)
- [Input JSON](https://github.com/BrenPatF/oracle_plsql_api_demos#input-json)
- [Output JSON](https://github.com/BrenPatF/oracle_plsql_api_demos#output-json)

#### Wrapper Function Signature Diagram
- [&uarr; Wrapper Function](https://github.com/BrenPatF/oracle_plsql_api_demos#wrapper-function)

Each of the APIs tested has a JSON structure diagram showing the input/output structure of the pure unit test wrapper functions, which can be viewed in the detail README files. Here is a generic diagram illustrating the kinds of group that are often appropriate for database APIs.

<img src="testing\API Demo JSDs, v1.1 - Generic JSD.png">

#### Input JSON
- [&uarr; Wrapper Function](https://github.com/BrenPatF/oracle_plsql_api_demos#wrapper-function)

As noted earlier, an easy way to generate a starting point for the input JSON file is to use a powershell utility [Powershell Utilites module](https://github.com/BrenPatF/powershell_utils) to generate a template file with a single scenario with placeholder records from simple CSV files. The CSV files for the generic JSON structure diagram above would look like this:

<img src="testing\CSV Screenshot.png">

The powershell utility can be run from a powershell window like this:

```powershell
Import-Module TrapitUtils
Write-UT_Template 'purely_wrap_uut' '|'
```

This generates the JSON template file, purely_wrap_uut_temp.json:
<pre>
{
   "meta":{
      "title":"title",
      "delimiter":"|",
      "inp":{
         "Parameter Scalars":[
            "Scalar 1",
            "Scalar 2"
         ],
         "Parameter Array":[
            "Element 1",
            "Element 2"
         ],
         "Input Table":[
            "Column 1",
            "Column 2"
         ]
      },
      "out":{
         "Return Array":[
            "Element 1",
            "Element 2"
         ],
         "Output Table":[
            "Column 1",
            "Column 2"
         ],
         "Exception":[
            "Error Code",
            "Error Message"
         ]
      }
   },
   "scenarios":{
      "scenario 1":{
         "active_yn":"Y",
         "inp":{
            "Parameter Scalars":[
               "|"
            ],
            "Parameter Array":[
               "|"
            ],
            "Input Table":[
               "|"
            ]
         },
         "out":{
            "Return Array":[
               "|"
            ],
            "Output Table":[
               "|"
            ],
            "Exception":[
               "|"
            ]
         }
      }
   }
}
</pre>
This template file has a single scenario, "scenario 1", with a single record in each group with null field values separated by the delimiter '|'. The developer copies and pastes the placeholder scenario as many times as necessary, replacing the null values with the real input values in the "inp" section, and with expected output values in the "out" section.

The files for this example are in the folder `testing`:
- Input CSV: purely_wrap_uut_inp.csv
- Output CSV: purely_wrap_uut_out.csv
- Powershell script: purely_wrap_uut.ps1
- Template JSON: purely_wrap_uut_temp.json


#### Output JSON
- [&uarr; Wrapper Function](https://github.com/BrenPatF/oracle_plsql_api_demos#wrapper-function)

The output JSON file is generated by the Trapit library module, so that the specific unit test wrapper functions do not deal with JSON syntax, or with the input and output JSON files, at all.

The output JSON file is based on the input file, but with each output group now containing two objects, "exp" holding the array of expected records from the input file, and "act" holding the array of actual records returned from the wrapper function. For example, the output JSON corresponding to the placeholder scenario above would be (with all values null in this illustration):

<pre>
         "out":{
            "Return Array":{
               "exp":[
                  "|"
               ],
               "act":[
                  "|"
               ]
            },
            "Output Table":{
               "exp":[
                  "|"
               ],
               "act":[
                  "|"
               ]
            },
            "Exception":{
               "exp":[
                  "|"
               ],
               "act":[
                  "|"
               ]
            }
         }
</pre>
### Unit Test Scenarios
- [&uarr; Unit Testing](https://github.com/BrenPatF/oracle_plsql_api_demos#unit-testing)
- [Input Data Category Sets](https://github.com/BrenPatF/oracle_plsql_api_demos#input-data-category-sets)
- [Scenario Results (Emp_WS.Save_Emps example)](https://github.com/BrenPatF/oracle_plsql_api_demos#scenario-results-emp_wssave_emps-example)

The art of unit testing lies in choosing a set of scenarios that will produce a high degree of confidence in the functioning of the unit under test across the often very large range of possible inputs.

A useful approach to this can be to think in terms of categories of inputs, where we reduce large ranges to representative categories. In each case we might consider the applicable category sets, and create scenarios accordingly. 

Often, some fairly generic category sets may be applied, such as those below (taken from the Emp_WS.Save_Emps example), with the scenarios being more specific to the unit under test.

#### Input Data Category Sets
- [&uarr; Unit Test Scenarios](https://github.com/BrenPatF/oracle_plsql_api_demos#unit-test-scenarios)
- [Validity](https://github.com/BrenPatF/oracle_plsql_api_demos#validity)
- [Multiplicity](https://github.com/BrenPatF/oracle_plsql_api_demos#multiplicity)
- [Exceptions](https://github.com/BrenPatF/oracle_plsql_api_demos#exceptions)

##### Validity
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/oracle_plsql_api_demos#input-data-category-sets)

Check valid and invalid records are handled correctly
- Valid
- Invalid

##### Multiplicity
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/oracle_plsql_api_demos#input-data-category-sets)

Check that both 1 and multiple valid records work, including with an invalid record
- 1 record
- Multiple valid records

##### Exceptions
- [&uarr; Input Data Category Sets](https://github.com/BrenPatF/oracle_plsql_api_demos#input-data-category-sets)

Check that different types of invalid record are handled correctly
- Foreign key error
- Invalid number

#### Scenario Results (Emp_WS.Save_Emps example)
- [&uarr; Unit Test Scenarios](https://github.com/BrenPatF/oracle_plsql_api_demos#unit-test-scenarios)
- [Results Summary](https://github.com/BrenPatF/oracle_plsql_api_demos#results-summary)
- [Results for Scenario 4: 2 valid records, 1 invalid job id (2 deliberate errors)](https://github.com/BrenPatF/oracle_plsql_api_demos#results-for-scenario-4-2-valid-records-1-invalid-job-id-2-deliberate-errors)

##### Results Summary
- [&uarr; Scenario Results (Emp_WS.Save_Emps example)](https://github.com/BrenPatF/oracle_plsql_api_demos#scenario-results-emp_wssave_emps-example)

The root page for the results in HTML format gives a summary report showing the scenarios tested, with links to scenario pages. This is an image of the root page for the Emp_WS.Save_Emps example:

<img src="testing\oracle-pl_sql-api-demos_-tt_emp_ws.save_emps.png">

##### Results for Scenario 4: 2 valid records, 1 invalid job id (2 deliberate errors)
- [&uarr; Scenario Results (Emp_WS.Save_Emps example)](https://github.com/BrenPatF/oracle_plsql_api_demos#scenario-results-emp_wssave_emps-example)

The scenario pages for the results in HTMl format list both inputs and outputs by group and record, and where actual records differ from expected both are listed in the output section. This is an image of the HTML page for the 4'th scenario for the Emp_WS.Save_Emps example:

<img src="testing\2-valid-records,-1-invalid-job-id-(2-deliberate-errors).png">

## Logging and Instrumentation
- [&uarr; In this README...](https://github.com/BrenPatF/oracle_plsql_api_demos#in-this-readme)

Program instrumentation means including lines of code to monitor the execution of a program, such as tracing lines covered, numbers of records processed, and timing information. Logging means storing such information, in database tables or elsewhere.

The Log_Set module allows for logging of various data in a lines table linked to a header for a given log, with the logging level configurable at runtime. The module also uses Oracle's DBMS_Application_Info API to allow for logging in memory only with information accessible via the V$SESSION and V$SESSION_LONGOPS views.

The two web service-type APIs, Emp_WS.Save_Emps and Emp_WS.Get_Dept_Emps, use a configuration that logs only via DBMS_Application_Info, while the batch API, Emp_Batch.Load_Emps, also logs to the tables. The view of course does not do any logging itself but calling programs can log the results of querying it.

The driver script api_driver.sql calls all four of the demo APIs and performs its own logging of the calls and the results returned, including the DBMS_Application_Info on exit. The driver logs using a special DEBUG configuration where the log is constructed implicitly by the first Put, and there is no need to pass a log identifier when putting (so debug lines can be easily added in any called package). At the end of the script queries are run that list the contents of the logs created during the session in creation order, first normal logs, then a listing for error logs (of which one is created by deliberately raising an exception handled in WHEN OTHERS).

<img src="Oracle PLSQL API Demos - LogSet-Flow.png">

<img src="Oracle PLSQL API Demos - LogSet.png">

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
- [&uarr; In this README...](https://github.com/BrenPatF/oracle_plsql_api_demos#in-this-readme)

The code timing module Timer_Set is used by the driver script, api_driver.sql, to time the various calls, and at the end of the main block the results are logged using Log_Set.

<img src="Oracle PLSQL API Demos - TimerSet-Flow.png">

<img src="Oracle PLSQL API Demos - TimerSet.png">

 The timing results are listed for illustration below:

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

## Functional PL/SQL
- [&uarr; In this README...](https://github.com/BrenPatF/oracle_plsql_api_demos#in-this-readme)

The recordings 1.5 and 1.6 show examples of the functional style of PL/SQL used in the utility packages demonstrated, and here is a diagram from 1.6 illustrating a design pattern identified in refactoring the main subprogram of the unit test programs.

<strong>30 May 2021</strong>: Note that a new version of the Trapit module has moved the main subprogram into its own library code, so that the main subprogram no longer exists in the specific (per API) unit test code.

<img src="Oracle PLSQL API Demos - Nested subprograms.png">

## Installation
- [&uarr; In this README...](https://github.com/BrenPatF/oracle_plsql_api_demos#in-this-readme)
- [Install 1: Install prerequisite tools](https://github.com/BrenPatF/oracle_plsql_api_demos#install-1-install-prerequisite-tools)
- [Install 2: Clone git repository](https://github.com/BrenPatF/oracle_plsql_api_demos#install-2-clone-git-repository)
- [Install 3: Install prerequisite modules](https://github.com/BrenPatF/oracle_plsql_api_demos#install-3-install-prerequisite-modules)
- [Install 4: Create Oracle PL/SQL API Demos components](https://github.com/BrenPatF/oracle_plsql_api_demos#install-4-create-oracle-plsql-api-demos-components)

### Install 1: Install prerequisite tools
- [&uarr; Installation](https://github.com/BrenPatF/oracle_plsql_api_demos#installation)

#### Oracle database with HR demo schema
The database installation requires a minimum Oracle version of 12.2, with Oracle's HR demo schema installed [Oracle Database Software Downloads](https://www.oracle.com/database/technologies/oracle-database-software-downloads.html).

If HR demo schema is not installed, it can be got from here: [Oracle Database Sample Schemas](https://docs.oracle.com/cd/E11882_01/server.112/e10831/installation.htm#COMSC001).

#### Github Desktop
In order to clone the code as a git repository you need to have the git application installed. I recommend [Github Desktop](https://desktop.github.com/) UI for managing repositories on windows. This depends on the git application, available here: [git downloads](https://git-scm.com/downloads), but can also be installed from within Github Desktop, according to these instructions: 
[How to install GitHub Desktop](https://www.techrepublic.com/article/how-to-install-github-desktop/).

#### nodejs (Javascript backend)
nodejs is needed to run a program that turns the unit test output files into formatted HTML pages. It requires no javascript knowledge to run the program, and nodejs can be installed [here](https://nodejs.org/en/download/).

### Install 2: Clone git repository
- [&uarr; Installation](https://github.com/BrenPatF/oracle_plsql_api_demos#installation)

The following steps will download the repository into a folder, oracle_plsql_api_demos, within your GitHub root folder:
- Open Github desktop and click [File/Clone repository...]
- Paste into the url field on the URL tab: https://github.com/BrenPatF/oracle_plsql_api_demos.git
- Choose local path as folder where you want your GitHub root to be
- Click [Clone]

### Install 3: Install prerequisite modules
- [&uarr; Installation](https://github.com/BrenPatF/oracle_plsql_api_demos#installation)

The demo install depends on the prerequisite modules Utils, Trapit, Log_Set, and Timer_Set, and `lib` and `app` schemas refer to the schemas in which Utils and examples are installed, respectively.

The prerequisite modules can be installed by following the instructions for each module at the module root pages listed in the `See also` section below. This allows inclusion of the examples and unit tests for those modules. Alternatively, the next section shows how to install these modules directly without their examples or unit tests here.

#### [Schema: sys; Folder: install_prereq] Create lib and app schemas and Oracle directory
install_sys.sql creates an Oracle directory, `input_dir`, pointing to 'c:\input'. Update this if necessary to a folder on the database server with read/write access for the Oracle OS user
- Run script from slqplus:
```
SQL> @install_sys
```
#### [Schema: lib; Folder: install_prereq\lib] Create lib components
- Run script from slqplus:
```
SQL> @install_lib_all
```
#### [Schema: app; Folder: install_prereq\app] Create app synonyms
- Run script from slqplus:
```
SQL> @c_syns_all
```
#### [Folder: (npm root)] Install npm trapit package
The npm trapit package is a nodejs package used to format unit test results as HTML pages.

Open a DOS or Powershell window in the folder where you want to install npm packages, and, with [nodejs](https://nodejs.org/en/download/) installed, run
```
$ npm install trapit
```
This should install the trapit nodejs package in a subfolder .\node_modules\trapit

### Install 4: Create Oracle PL/SQL API Demos components
- [&uarr; Installation](https://github.com/BrenPatF/oracle_plsql_api_demos#installation)
#### [Folder: (root)]
- Copy the following files from the root folder to the server folder pointed to by the Oracle directory INPUT_DIR:
    - tt_emp_ws.purely_wrap_save_emps_inp.json
    - tt_emp_ws.purely_wrap_get_dept_emps_inp.json
    - tt_emp_batch.purely_wrap_load_emps_inp.json
    - tt_view_drivers.purely_wrap_hr_test_view_v_inp.json

- There is also a bash script to do this, assuming C:\input as INPUT_DIR:
```
$ ./cp_json_to_input.sh
```

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
- [In this README...](https://github.com/BrenPatF/oracle_plsql_api_demos#in-this-readme)
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

- tt_emp_batch.purely_wrap_load_emps_out.json
- tt_emp_ws.purely_wrap_get_dept_emps_out.json
- tt_emp_ws.purely_wrap_save_emps_out.json
- tt_view_drivers.purely_wrap_hr_test_view_v_out.json

The output files are processed by a nodejs program that has to be installed separately, from the `npm` nodejs repository, as described in the Installation section above. The nodejs program produces listings of the results in HTML and/or text format, and result files are included in the subfolders below test_output. To run the processor (in Windows), open a DOS or Powershell window in the trapit package folder after placing the output JSON files in the subfolder ./examples/externals and run:

```
$ node ./examples/externals/test-externals
```

## Operating System/Oracle Versions
- [&uarr; In this README...](https://github.com/BrenPatF/oracle_plsql_api_demos#in-this-readme)

### Windows
Tested on Windows 10, should be OS-independent

### Oracle
- Tested on Oracle Database Version 19.3.0.0.0 (minimum required: 12.2)

## See also
- [Utils - Oracle PL/SQL general utilities module](https://github.com/BrenPatF/oracle_plsql_utils)
- [Trapit - Oracle PL/SQL unit testing module](https://github.com/BrenPatF/trapit_oracle_tester)
- [Log_Set - Oracle logging module](https://github.com/BrenPatF/log_set_oracle)
- [Timer_Set - Oracle PL/SQL code timing module](https://github.com/BrenPatF/timer_set_oracle)
- [Trapit - nodejs unit test processing package](https://github.com/BrenPatF/trapit_nodejs_tester)

## License
MIT
