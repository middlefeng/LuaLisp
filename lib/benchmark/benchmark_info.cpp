//
//  benchmark_info.cpp
//  benchmark
//
//  Created by Middleware on 4/4/15.
//  Copyright (c) 2015 fengdong. All rights reserved.
//

#include "benchmark_info.h"

#include <string>
#include <unordered_map>
#include <list>

#include <sys/time.h>


static double system_time();


static std::unordered_map<std::string, double> function_calls_time;



enum function_call_state
{
	function_call_begin,
	function_call_end
};

struct function_call
{
	function_call_state state;
	double time;
};

typedef std::list<function_call> function_call_events;
typedef std::unordered_map<std::string, function_call_events> system_call_events_type;


static system_call_events_type system_call_events;


void function_called(const char* name)
{
	// get the current time;
	struct function_call this_call;
	this_call.state = function_call_begin;
	this_call.time = system_time();
	
	auto it = system_call_events.find(name);
	
	if (it == system_call_events.end()) {
		function_call_events events;
		system_call_events.insert(std::make_pair(std::string(name), events));
	}
	
	function_call_events& call_events = system_call_events[name];
	call_events.push_back(this_call);
}




void function_returned(const char* name)
{
	double end_time = system_time();
	
	auto it = system_call_events.find(name);
	if (it == system_call_events.end()) {
		printf("Error: %s is not called.\n", name);
		return;
	}
	
	function_call_events& call_events = system_call_events[name];
	struct function_call this_call = call_events.back();
	call_events.pop_back();
	
	double run_time = end_time - this_call.time;
	
	auto it_a = function_calls_time.find(name);
	if (it_a != function_calls_time.end())
		run_time += function_calls_time[name];
	
	function_calls_time[name] = run_time;
}




struct query_result
{
	const char** names;
	double* times;
	size_t count;
};

static query_result query_result_set;


void function_calls_info(const char*** name, double** time, size_t* count)
{
	system_call_events.clear();
	
	*count = function_calls_time.size();
	
	query_result_set.count = *count;
	query_result_set.names = new const char*[*count];
	query_result_set.times = new double[*count];
	
	auto it = function_calls_time.begin();
	for (size_t i = 0; i < *count; ++i) {
		query_result_set.names[i] = it->first.c_str();
		query_result_set.times[i] = it->second;
		++it;
	}
	
	*name = query_result_set.names;
	*time = query_result_set.times;
}



void function_calls_info_clear()
{
	delete[] query_result_set.names;
	delete[] query_result_set.times;
	query_result_set.count = 0;
	
	function_calls_time.clear();
}







double system_time()
{
	struct timeval timev;
	gettimeofday(&timev, NULL);
	return timev.tv_sec + ((float)timev.tv_usec) / 1000000.0;
}

