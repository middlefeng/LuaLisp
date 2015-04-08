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
	std::string name;
	double time;
};

std::list<function_call> function_call_stack;


void function_called(const char* name)
{
	double time = system_time();
	
	// get the current time;
	struct function_call this_call;
	this_call.name = name;
	this_call.time = time;
	
	function_call_stack.push_back(this_call);
}




void function_tailcalled(const char* name)
{
	function_returned();
	function_called(name);
}




void function_returned()
{
	if (function_call_stack.size() == 0)
		return;
	
	double end_time = system_time();
	
	struct function_call& topest_call = function_call_stack.back();
	double run_time = end_time - topest_call.time;
	
	auto it_a = function_calls_time.find(topest_call.name);
	if (it_a != function_calls_time.end())
		run_time += function_calls_time[topest_call.name];
	
	function_calls_time[topest_call.name] = run_time;
	function_call_stack.pop_back();
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
	function_call_stack.clear();
	
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

