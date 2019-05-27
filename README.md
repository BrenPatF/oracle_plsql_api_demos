# Oracle_PLSQL_API_Demos
Demonstrating Oracle PL/SQL API procedures for getting and setting database data, with code timing, message logging and unit testing. 

27 May 2019: Work in progress: Copied from trapit_oracle_tester and planning to restructure so that calls are made to separate modules for unit testing and other utility code. 

TRansactional API Test (TRAPIT) utility packages for Oracle plus demo base and test programs for Oracle's HR demo schema.

The test utility packages and types are designed as a lightweight PL/SQL-based framework for API testing that can be considered as an alternative to utPLSQL. The framework is based on the idea that all API testing programs can follow a universal design pattern for testing APIs, using the concept of a ‘pure’ function as a wrapper to manage the ‘impurity’ inherent in database APIs. I explained the concepts involved in a presentation at the Oracle User Group Ireland Conference in March 2018:

<a href="https://www.slideshare.net/brendanfurey7/database-api-viewed-as-a-mathematical-function-insights-into-testing" target="_blank">The Database API Viewed As A Mathematical Function: Insights into Testing</a>

The following article provides example output and links to articles describing design patterns the framework is designed to facilitate, as well as anti-patterns it is designed to discourage:

<a href="http://aprogrammerwrites.eu/?p=1723" target="_blank">TRAPIT - TRansactional API Testing in Oracle</a>

6 July 2018: json_input_output feature branch created that moves all inputs out of the packages and into JSON files, and creates output JSON files that include the actuals. A new table is added to store the input and output JSON files by package and procedure. The output files can be used as inputs to a Nodejs program, recently added to GitHub, to produce result reports formatted in both HTML and text. The input JSON files are read into the new table at installation time, and read from the table thereafter. The Nodejs project includes the formatted reports for this Oracle project. The output JSON files are written to Oracle directory input_dir (and the input JSON files are read from there), but I have copied them into the project oracle root for reference.

<a href="https://github.com/BrenPatF/trapit_nodejs_tester" target="_blank">trapit_nodejs_tester</a>

Pre-requisites
==============
In order to run the demo unit test suite, you must have installed Oracle's HR demo schema on your Oracle instance:

<a href="https://docs.oracle.com/cd/E11882_01/server.112/e10831/installation.htm#COMSC001" target="_blank">Oracle Database Sample Schemas</a>
    
There are no other dependencies outside this project, other than that the latest, JSON, version produces JSON outputs but not formatted reports, which can be obtained from my Nodejs project, mentioned above. I may add a PL/SQL formatter at a later date.

Output logging
==============
The testing utility packages use my own simple logging framework, installed as part of the installation scripts. To replace this with your own preferred logging framework, simply edit the procedure Utils.Write_Log to output using your own logging procedure, and optionally drop the log_headers and log_lines tables, along with the three Utils.*_Log methods.

As far as I know, prior to the latest JSON version, the code should work on any recent-ish version - I have tested on 11.2 and 12.1. The JSON version may require 12.2.

Install steps
=============
 	Extract all the files into a directory
 	Update Install_SYS.sql to ensure Oracle directory input_dir points to a writable directory on the database sever (in repo now is set to 'C:\input')
	Copy the input JSON files to the directory pointed to by input_dir:
		TT_EMP_BATCH.tt_AIP_Load_Emps.json
		TT_EMP_WS.tt_AIP_Get_Dept_Emps.json
		TT_EMP_WS.tt_AIP_Save_Emps.json
		TT_VIEW_DRIVERS.tt_HR_Test_View_V.json
 	Run Install_SYS.sql as a DBA passing new library schema name as parameter (eg @Install_SYS trapit)
 	Run Install_HR.sql from the HR schema passing library utilities schema name as parameter  (eg @Install_HR trapit)
 	Run Install_Bren.sql from the schema for the library utilities (@Install_Bren)
 	Check log files for any errors

Running the demo test suite
===========================
Run R_Suite_br.sql from the schema for the library utilities in the installation directory.