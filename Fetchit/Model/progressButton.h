//
//  progressButton.h
//  UIActivityViewController test
//
//  Created by 581 on 2014/4/20.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface progressButton : UIButton


- (id)initWithFrame:(CGRect)frame;
- (void) setDynamicTransferSpeed:(NSString*) transferSpeed;
- (void) setProgress: (float)progress;
- (void) setFileSize: (NSString*) fileSize;
- (void) setFileTitle:(NSString *)title;
- (void) transferDidEnd;
- (void) transferBegin;
@end
