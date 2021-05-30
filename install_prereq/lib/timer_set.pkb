CREATE OR REPLACE PACKAGE BODY Timer_Set AS
/***************************************************************************************************
Name: timer_set.pkb                    Author: Brendan Furey                       Date: 29-Jan-2019

Package body component in the timer_set_oracle module. This module facilitates code timing for 
instrumentation and other purposes, with very small footprint in both code and resource usage.

    GitHub: https://github.com/BrenPatF/timer_set_oracle

====================================================================================================
|  Package    |  Notes                                                                             |
|==================================================================================================|
| *Timer_Set* |  Code timing package                                                               |
====================================================================================================

This file has the Timer_Set package body. See README for API specification, and the 
main_col_group.sql script for simple examples of use.

***************************************************************************************************/

OTH_TIMER                        CONSTANT VARCHAR2(10) := '(Other)';
TOT_TIMER                        CONSTANT VARCHAR2(10) := 'Total';
MIN_CALLS_WIDTH                  CONSTANT PLS_INTEGER := 5;
MIN_TOT_TIME_WIDTH               CONSTANT PLS_INTEGER := 6;
MIN_TOT_RATIO_WIDTH              CONSTANT PLS_INTEGER := 8;
SELF_TIME                        CONSTANT NUMBER := 0.1;
CS_SECS_FACTOR                   CONSTANT NUMBER := 0.01;
SECS_MS_FACTOR                   CONSTANT PLS_INTEGER := 1000;
TIME_FMT                         CONSTANT VARCHAR2(30) := 'HH24:MI:SS';
DATETIME_FMT                     CONSTANT VARCHAR2(30) := 'DD Mon RRRR ' || TIME_FMT;

TYPE timer_rec IS RECORD (
            name                           VARCHAR2(100),
            ela_interval                   INTERVAL DAY(1) TO SECOND,
            cpu_interval                   INTEGER,
            calls                          INTEGER);
TYPE timer_arr IS VARRAY(100) OF timer_rec;
TYPE hash_arr IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(100);
TYPE timer_set_rec IS RECORD (
            timer_set_name                 VARCHAR2(100),
            start_time                     time_point_rec,
            prior_time                     time_point_rec,
            timer_lis                      timer_arr,
            timer_hash                     hash_arr,
            result_lis                     timer_stat_arr,
            is_mocked                      BOOLEAN);

TYPE timer_set_arr IS TABLE OF timer_set_rec;

g_timer_set_lis    timer_set_arr;
g_mock_time_lis    time_point_arr;
g_mock_time_ind    PLS_INTEGER;

/***************************************************************************************************

get_Times: Gets elapsed and CPU times using system calls (or mocks) and returns as tuple

***************************************************************************************************/
FUNCTION get_Times(
            p_is_mocked                    BOOLEAN DEFAULT FALSE)  -- mock boolean
            RETURN                         time_point_rec IS       -- ela, cpu pair
  l_time_point_rec    time_point_rec;
BEGIN
  IF p_is_mocked THEN
    g_mock_time_ind := g_mock_time_ind + 1;
    l_time_point_rec := g_mock_time_lis(g_mock_time_ind);
  ELSE
    l_time_point_rec.ela := SYSTIMESTAMP;
    l_time_point_rec.cpu := DBMS_Utility.Get_CPU_Time;
  END IF;

  RETURN l_time_point_rec;

END get_Times;

/***************************************************************************************************

set_Timer_Stat_Rec: Returns a timer statistics record, converting a timer record

***************************************************************************************************/
FUNCTION set_Timer_Stat_Rec(
            p_timer_rec                    timer_rec)        -- timer record
            RETURN                         timer_stat_rec IS -- timer statistics record
  l_timer_stat_rec  timer_stat_rec;
BEGIN

  l_timer_stat_rec.name     := p_timer_rec.name;
  l_timer_stat_rec.ela_secs := Utils.IntervalDS_To_Seconds(p_timer_rec.ela_interval);
  l_timer_stat_rec.cpu_secs := CS_SECS_FACTOR * p_timer_rec.cpu_interval;
  l_timer_stat_rec.calls    := p_timer_rec.calls;

  RETURN l_timer_stat_rec;

END set_Timer_Stat_Rec;

/***************************************************************************************************

set_Timer_Rec: Returns a timer record, incrementing an existing timer record if passed

***************************************************************************************************/
FUNCTION set_Timer_Rec(
            p_name                         VARCHAR2,               -- timer name
            p_ela_interval                 INTERVAL DAY TO SECOND, -- elapsed seconds interval
            p_cpu_interval                 INTEGER,                -- CPU centi-seconds
            p_calls                        INTEGER,                -- # calls
            p_timer_rec                    timer_rec DEFAULT NULL) -- optional passed timer record
            RETURN                         timer_rec IS            -- returned timer record

  l_timer_rec             timer_rec := p_timer_rec;
BEGIN

  IF p_timer_rec.name IS NULL THEN
    l_timer_rec.name         := p_name;
    l_timer_rec.ela_interval := p_ela_interval;
    l_timer_rec.cpu_interval := p_cpu_interval;
    l_timer_rec.calls        := p_calls;
  ELSE
    l_timer_rec.ela_interval := l_timer_rec.ela_interval + p_ela_interval;
    l_timer_rec.cpu_interval := l_timer_rec.cpu_interval + p_cpu_interval;
    l_timer_rec.calls        := l_timer_rec.calls + p_calls;
  END IF;

  RETURN l_timer_rec;

END set_Timer_Rec;

/***************************************************************************************************

val_Widths: Handle parameter defaulting, and validate width parameters

***************************************************************************************************/
PROCEDURE val_Widths(
            p_format_prms                  format_prm_rec) IS -- format parameters
BEGIN

  IF p_format_prms.calls_width < MIN_CALLS_WIDTH THEN
    Utils.Raise_Error('Error, calls_width must be >= ' || MIN_CALLS_WIDTH || ', actual: ' ||
       p_format_prms.calls_width);
  ELSIF p_format_prms.time_width < 0 OR p_format_prms.time_dp < 0 
                                     OR p_format_prms.time_ratio_dp < 0 THEN
    Utils.Raise_Error('Error, time_width, time_dp, time_ratio_dp must be > 0, actual: ' || 
        p_format_prms.time_width || ', ' || p_format_prms.time_dp || ', ' || 
        p_format_prms.time_ratio_dp);
  ELSIF p_format_prms.time_width + p_format_prms.time_dp < MIN_TOT_TIME_WIDTH THEN
    Utils.Raise_Error('Error, time_width + time_dp must be >= ' || MIN_TOT_TIME_WIDTH ||
        ', actual: ' ||p_format_prms.time_width || ' + ' || p_format_prms.time_dp);
  ELSIF p_format_prms.time_width + p_format_prms.time_ratio_dp < MIN_TOT_RATIO_WIDTH THEN
    Utils.Raise_Error('Error, time_width + time_dp must be >= ' || MIN_TOT_RATIO_WIDTH ||
        ', actual: ' || p_format_prms.time_width || ' + ' || p_format_prms.time_ratio_dp);
  END IF;
    
END val_Widths;

/***************************************************************************************************

form_Time: Format a numeric time as a string

***************************************************************************************************/
FUNCTION form_Time(
            p_time                         NUMBER,      -- time to format
            p_width                        PLS_INTEGER, -- display width excluding dp
            p_dp                           PLS_INTEGER) -- decimal places
            RETURN                         VARCHAR2 IS  -- formatted time
  l_dp_zeros  VARCHAR2(10) := Substr('0000000000', 1, p_dp);
BEGIN
  IF p_dp > 0 THEN l_dp_zeros := '.' || l_dp_zeros; END IF;
  RETURN Substr(To_Char (p_time, Substr('9999999999999', 1, 
      p_width - CASE WHEN p_dp > 0 THEN 2 ELSE 1 END) || '0' || l_dp_zeros), 2);
END form_Time;

/***************************************************************************************************

form_Calls: Format number of calls as a string

***************************************************************************************************/
FUNCTION form_Calls(
            p_calls                        PLS_INTEGER, -- number of calls
            p_width                        PLS_INTEGER) -- display width
            RETURN                         VARCHAR2 IS  -- formatted number of calls
BEGIN
  RETURN To_Char(p_calls, Substr('9999999999', 1, p_width - 2) || '0');
END form_Calls;

/***************************************************************************************************

Null_Mock: Set null the two package mocking variables, call it in unit testing before new scenario

***************************************************************************************************/
PROCEDURE Null_Mock IS
BEGIN

  g_mock_time_lis := NULL;
  g_mock_time_ind := NULL;

END Null_Mock;

/***************************************************************************************************

Remove_Timer_Set: Removes a timer set

***************************************************************************************************/
PROCEDURE Remove_Timer_Set(
            p_timer_set_id                 PLS_INTEGER) IS -- timer set id
BEGIN

  g_timer_set_lis.DELETE(p_timer_set_id );

END Remove_Timer_Set;

/***************************************************************************************************

Construct: Constructs a new timer set, returning its id

***************************************************************************************************/
FUNCTION Construct(
            p_timer_set_name               VARCHAR2,                    -- timer set name
            p_mock_time_lis                time_point_arr DEFAULT NULL) -- list of mock ela, cpu pairs
            RETURN                         PLS_INTEGER IS               -- timer set id
  l_time_point_rec       time_point_rec;
  l_new_ind              PLS_INTEGER;
  l_timer_set            timer_set_rec;
  l_is_mocked            BOOLEAN := p_mock_time_lis IS NOT NULL;
BEGIN

  IF g_mock_time_lis IS NULL AND l_is_mocked THEN -- One mock array per session
    g_mock_time_lis := p_mock_time_lis;
    g_mock_time_ind := 0;
  END IF;

  l_time_point_rec := get_Times(l_is_mocked);
  l_timer_set.timer_set_name := p_timer_set_name;
  l_timer_set.start_time     := l_time_point_rec;
  l_timer_set.prior_time     := l_time_point_rec;
  l_timer_set.is_mocked      := l_is_mocked;

  IF g_timer_set_lis IS NULL THEN
    l_new_ind := 1;
    g_timer_set_lis := timer_set_arr(l_timer_set);
  ELSE
    g_timer_set_lis.EXTEND;
    l_new_ind := g_timer_set_lis.COUNT;
    g_timer_set_lis(l_new_ind) := l_timer_set;
  END IF;

  RETURN l_new_ind;

END Construct;

/***************************************************************************************************

Init_Time: Resets the prior time values, to current, for a timer set

***************************************************************************************************/
PROCEDURE Init_Time(
            p_timer_set_id                 PLS_INTEGER) IS -- timer set id
BEGIN
  g_timer_set_lis(p_timer_set_id).prior_time := get_Times(g_timer_set_lis(p_timer_set_id).is_mocked);
END Init_Time;

/***************************************************************************************************

Increment_Time: Increments the timing accumulators for a timer set and timer

***************************************************************************************************/
PROCEDURE Increment_Time(
            p_timer_set_id                 PLS_INTEGER, -- timer set id
            p_timer_name                   VARCHAR2) IS -- timer name

  l_time_point_rec        time_point_rec := get_Times(g_timer_set_lis(p_timer_set_id).is_mocked);
  l_timer_ind             PLS_INTEGER := 0;
  l_timer                 timer_rec;

  l_timer_lis             timer_arr := g_timer_set_lis(p_timer_set_id).timer_lis;
  l_timer_hash            hash_arr := g_timer_set_lis(p_timer_set_id).timer_hash;
  l_prior_time_point_rec  time_point_rec := g_timer_set_lis(p_timer_set_id).prior_time;
BEGIN

  l_timer.name          := p_timer_name;
  l_timer.ela_interval  := l_time_point_rec.ela - l_prior_time_point_rec.ela;
  l_timer.cpu_interval  := l_time_point_rec.cpu - l_prior_time_point_rec.cpu;
  l_timer.calls         := 1;

  IF l_timer_lis IS NULL THEN

    l_timer_lis := timer_arr(l_timer);
    g_timer_set_lis(p_timer_set_id).timer_lis := l_timer_lis;
    g_timer_set_lis(p_timer_set_id).timer_hash(p_timer_name) := 1;

  ELSE

    IF l_timer_hash.EXISTS(p_timer_name) THEN

      l_timer_ind := l_timer_hash(p_timer_name);
      g_timer_set_lis(p_timer_set_id).timer_lis(l_timer_ind) :=
        set_Timer_Rec(NULL, l_timer.ela_interval, l_timer.cpu_interval, 1, l_timer_lis(l_timer_ind));

    ELSE

      l_timer_ind := l_timer_lis.COUNT + 1;
      g_timer_set_lis(p_timer_set_id).timer_lis.EXTEND;
      g_timer_set_lis(p_timer_set_id).timer_lis(l_timer_ind) := l_timer;
      g_timer_set_lis(p_timer_set_id).timer_hash(p_timer_name) := l_timer_ind;

    END IF;

  END IF;

  g_timer_set_lis(p_timer_set_id).prior_time := l_time_point_rec;

END Increment_Time;

/***************************************************************************************************

Get_Timers: Returns the results for timer set in an array of timer set statistics records

***************************************************************************************************/
FUNCTION Get_Timers(
            p_timer_set_id                 PLS_INTEGER)      -- timer set id
            RETURN                         timer_stat_arr IS -- timers array of records
  l_start_time_point_rec        time_point_rec;
  l_end_time_point_rec          time_point_rec;
  l_tot_time_rec                timer_rec;
  l_sum_time_rec                timer_rec;
  l_timer_rec                   timer_rec;
  l_timer_lis                   timer_arr;
  l_result_lis                  timer_stat_arr;
  l_sum_ela_interval            INTERVAL DAY(1) TO SECOND := '0 00:00:00';
  l_sum_cpu                     NUMBER := 0;
  l_sum_calls                   NUMBER := 0;
  l_n_timer                     NUMBER := 0;
BEGIN

  IF g_timer_set_lis(p_timer_set_id).result_lis IS NULL THEN

    l_result_lis := timer_stat_arr();
    l_timer_lis := g_timer_set_lis(p_timer_set_id).timer_lis;
    l_start_time_point_rec      := g_timer_set_lis(p_timer_set_id).start_time;
    l_end_time_point_rec        := get_Times(g_timer_set_lis(p_timer_set_id).is_mocked);
    IF l_timer_lis IS NOT NULL THEN
      l_n_timer := l_timer_lis.COUNT;
    END IF;
    l_result_lis.EXTEND(l_n_timer + 2);
    FOR i IN 1..l_n_timer LOOP

      l_timer_rec := l_timer_lis(i);
      l_result_lis(i) := set_Timer_Stat_Rec(l_timer_rec);
      l_sum_ela_interval := l_sum_ela_interval + l_timer_rec.ela_interval;
      l_sum_cpu := l_sum_cpu + l_timer_rec.cpu_interval;
      l_sum_calls := l_sum_calls + l_timer_rec.calls;

    END LOOP;
    l_tot_time_rec := set_Timer_Rec(TOT_TIMER, 
                                     l_end_time_point_rec.ela - l_start_time_point_rec.ela, 
                                     l_end_time_point_rec.cpu - l_start_time_point_rec.cpu,
                                     l_sum_calls + 1);
    l_result_lis(l_result_lis.COUNT - 1) := 
        set_Timer_Stat_Rec(set_Timer_Rec(OTH_TIMER,
                                           l_tot_time_rec.ela_interval - l_sum_ela_interval,
                                           l_tot_time_rec.cpu_interval - l_sum_cpu, 1));
    l_result_lis(l_result_lis.COUNT) := set_Timer_Stat_Rec(l_tot_time_rec);
    g_timer_set_lis(p_timer_set_id).result_lis := l_result_lis;

  END IF;
  RETURN g_timer_set_lis(p_timer_set_id).result_lis;

END Get_Timers;

/***************************************************************************************************

Format_Timers: Writes the timers to an array of formatted strings for the timer set

***************************************************************************************************/
FUNCTION Format_Timers(
            p_timer_set_id                 PLS_INTEGER,                            -- timer set id
            p_format_prms                  format_prm_rec DEFAULT FORMAT_PRMS_DEF) -- format params
            RETURN                         L1_chr_arr IS                           -- timers array

  l_head_len          PLS_INTEGER := 0;
  l_timer_stat_lis    timer_stat_arr;
  l_ret_lis           L1_chr_arr;
  l_timer_stat_rec    timer_stat_rec;
  l_ret_lis_ind       PLS_INTEGER := 2;
  l_time_width        PLS_INTEGER;
  l_time_ratio_width  PLS_INTEGER;
BEGIN
  val_Widths(p_format_prms);
  l_time_width         := p_format_prms.time_width + p_format_prms.time_dp + 
                            CASE WHEN p_format_prms.time_dp = 0 THEN 1 ELSE 0 END;
  l_time_ratio_width   := p_format_prms.time_width + p_format_prms.time_ratio_dp + 
                            CASE WHEN p_format_prms.time_dp = 0 THEN 1 ELSE 0 END;
  l_timer_stat_lis     := Get_Timers(p_timer_set_id);
  FOR i IN 1..l_timer_stat_lis.COUNT LOOP
    IF Length (l_timer_stat_lis(i).name) > l_head_len THEN
      l_head_len := Length (l_timer_stat_lis(i).name);
    END IF;
  END LOOP;

  l_ret_lis := Utils.Col_Headers(
                  p_value_lis => chr_int_arr(chr_int_rec('Timer', l_head_len), 
                                             chr_int_rec('Elapsed', -l_time_width),
                                             chr_int_rec('CPU', -l_time_width),
                                             chr_int_rec('Calls', -p_format_prms.calls_width),
                                             chr_int_rec('Ela/Call', -l_time_ratio_width),
                                             chr_int_rec('CPU/Call', -l_time_ratio_width)
                                 )
               );
  l_ret_lis.EXTEND(l_timer_stat_lis.COUNT + 2);
  FOR i IN 1..l_timer_stat_lis.COUNT LOOP
    l_timer_stat_rec := l_timer_stat_lis(i);
    l_ret_lis_ind := l_ret_lis_ind + 1;
    l_ret_lis(l_ret_lis_ind) := 
      Utils.List_To_Line(p_value_lis => chr_int_arr(
        chr_int_rec(RPad(l_timer_stat_rec.name, l_head_len), 
                    l_head_len), 
        chr_int_rec(form_Time(l_timer_stat_rec.ela_secs,
                              p_format_prms.time_width, 
                              p_format_prms.time_dp), 
                    -l_time_width),
        chr_int_rec(form_Time(l_timer_stat_rec.cpu_secs,
                              p_format_prms.time_width, 
                              p_format_prms.time_dp), 
                    -l_time_width),
        chr_int_rec(form_Calls(l_timer_stat_rec.calls, 
                               p_format_prms.calls_width), 
                    -p_format_prms.calls_width),
        chr_int_rec(form_Time(l_timer_stat_rec.ela_secs/l_timer_stat_rec.calls, 
                              p_format_prms.time_width, p_format_prms.time_ratio_dp),
                    -l_time_ratio_width),
        chr_int_rec(form_Time(l_timer_stat_rec.cpu_secs/l_timer_stat_rec.calls, 
                              p_format_prms.time_width, p_format_prms.time_ratio_dp),
                    -l_time_ratio_width)
      ));
    IF i > l_timer_stat_lis.COUNT - 2 THEN
      l_ret_lis_ind := l_ret_lis_ind + 1;
      l_ret_lis(l_ret_lis_ind) := l_ret_lis(2);
    END IF;

  END LOOP;
  RETURN l_ret_lis;

END Format_Timers;

/***************************************************************************************************

Get_Self_Timer: Static function returns 2-element array with timings per call for calling 
  Increment_time

***************************************************************************************************/
FUNCTION Get_Self_Timer
            RETURN                         L1_num_arr IS -- ela, cpu times in ms per call
  l_self_timer        PLS_INTEGER;
  l_i                 PLS_INTEGER := 0;
  l_t_ela             NUMBER := 0;
  l_tmstp             TIMESTAMP := SYSTIMESTAMP;
  l_timer_stat_lis    timer_stat_arr;
BEGIN

  l_self_timer := Construct ('Self');
  WHILE l_t_ela < SELF_TIME LOOP

    Increment_time(l_self_timer, 'x');
    l_i := l_i + 1;
    IF Mod(l_i, 100) = 0 THEN
      l_t_ela := Utils.IntervalDS_To_Seconds(SYSTIMESTAMP - l_tmstp);
    END IF;

  END LOOP;
  l_timer_stat_lis := Get_Timers(l_self_timer);
  RETURN  L1_num_arr(l_timer_stat_lis(1).ela_secs/l_i, l_timer_stat_lis(1).cpu_secs/l_i);

END Get_Self_Timer;

/***************************************************************************************************

Format_Self_Timer: Static function returns formatted string with the results of get_self_timer

***************************************************************************************************/
FUNCTION Format_Self_Timer(
            p_format_prms                  format_prm_rec DEFAULT FORMAT_PRMS_DEF) -- format params
            RETURN                         VARCHAR2 IS                             -- formatted self timer
  l_self_time_lis     L1_num_arr := Get_Self_Timer;
BEGIN
  val_Widths(p_format_prms);
  RETURN '[Timer timed (per call in ms): Elapsed: ' || 
         LTrim(form_Time(SECS_MS_FACTOR * l_self_time_lis(1), p_format_prms.time_width, 
          p_format_prms.time_ratio_dp)) ||', CPU: ' ||
         LTrim(form_Time(SECS_MS_FACTOR * l_self_time_lis(2), p_format_prms.time_width,
          p_format_prms.time_ratio_dp)) || ']';

END Format_Self_Timer;

/***************************************************************************************************

Format_Results: Returns array of formatted strings with the complete results, using Format_Timers;
  includes self timing results

***************************************************************************************************/
FUNCTION Format_Results(
            p_timer_set_id                 PLS_INTEGER,                            -- timer set id
            p_format_prms                  format_prm_rec DEFAULT FORMAT_PRMS_DEF) -- format params
            RETURN                         L1_chr_arr IS                           -- results

  l_ret_lis           L1_chr_arr := Utils.Heading('Timer Set: ' || 
      g_timer_set_lis(p_timer_set_id).timer_set_name ||
      ', Constructed at ' || 
      To_Char(g_timer_set_lis(p_timer_set_id).start_time.ela, DATETIME_FMT) ||
      ', written at ' || To_Char(SYSDATE, TIME_FMT));
  l_timer_stat_lis L1_chr_arr := Format_Timers(p_timer_set_id, p_format_prms);

BEGIN

  l_ret_lis.EXTEND(l_timer_stat_lis.COUNT + 1);
  FOR i IN 1..l_timer_stat_lis.COUNT LOOP
    l_ret_lis(i + 2) := l_timer_stat_lis(i);
  END LOOP;
  l_ret_lis(l_timer_stat_lis.COUNT + 3) := Format_Self_Timer(p_format_prms);
  RETURN l_ret_lis;

END Format_Results;

END Timer_Set;
/
SHOW ERROR