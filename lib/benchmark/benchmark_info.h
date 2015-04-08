//
//  benchmark_info.h
//  benchmark
//
//  Created by Middleware on 4/4/15.
//  Copyright (c) 2015 fengdong. All rights reserved.
//

#ifndef __benchmark__benchmark_info__
#define __benchmark__benchmark_info__

#include <stdio.h>


#ifdef __cplusplus
#define C_API extern "C"
#else
#define C_API extern
#endif


C_API void function_called(const char* name);
C_API void function_tailcalled(const char* name);
C_API void function_returned();

C_API void function_calls_info(const char*** name, double** time, size_t* count);
C_API void function_calls_info_clear();



#endif /* defined(__benchmark__benchmark_info__) */
