//
//  sample.h
//  YFCameraDemo
//
//  Created by wangfeng on 16/12/6.
//  Copyright © 2016年 abc. All rights reserved.
//

#ifndef sample_h
#define sample_h

#import <opencv2/core/core_c.h>

void initParams(void* cascade);

void process_image(IplImage* frame, int draw);

#endif /* sample_h */
