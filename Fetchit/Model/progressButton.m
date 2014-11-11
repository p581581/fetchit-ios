//
//  progressButton.m
//  UIActivityViewController test
//
//  Created by 581 on 2014/4/20.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import "progressButton.h"

@interface progressButton ()

@property UIProgressView * progressView;
@property UILabel * transferSpeed;
@property UILabel * fileInfo;

@end

@implementation progressButton


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(30, 50, 700, 2)];
        self.transferSpeed = [[UILabel alloc] initWithFrame:CGRectMake(30, 60, 150, 20)];
        self.fileInfo = [[UILabel alloc] initWithFrame:CGRectMake(500, 60, 150, 20)];
        
        UIFont *font = [UIFont systemFontOfSize:22];
        
        // Set title
        [self.titleLabel setFont:[UIFont systemFontOfSize:28]];
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        self.titleEdgeInsets = UIEdgeInsetsMake(6.0, 30.0, 0.0, 0.0);
        
        // Set the label of transfer Speed
        [self.transferSpeed setTextAlignment:NSTextAlignmentLeft];
        self.transferSpeed.text = @"4.09 Mb/s";
        self.transferSpeed.textColor = [UIColor whiteColor];
        [self.transferSpeed setFont:font];
        self.transferSpeed.adjustsFontSizeToFitWidth = YES;
        self.transferSpeed.hidden = YES;

        // Set the label of file size and status
        [self.fileInfo setTextAlignment:NSTextAlignmentRight];
        self.fileInfo.textColor = [UIColor whiteColor];
        [self.fileInfo setFont:font];
        self.fileInfo.adjustsFontSizeToFitWidth = YES;
        
        // Set progogress view
        self.progressView.progressTintColor = [UIColor redColor];
        self.progressView.trackTintColor = [UIColor grayColor];

        [self addSubview:self.transferSpeed];
        [self addSubview:self.fileInfo];
        [self addSubview:self.progressView];
        [self bringSubviewToFront:self.fileInfo];
        [self bringSubviewToFront:self.transferSpeed];
        [self addTarget:self action:@selector(touched:) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(touching:) forControlEvents:UIControlEventTouchDown];
        
    }
    return self;
}

- (IBAction)touched:(id)sender{
    self.backgroundColor = NULL;
}

- (IBAction)touching:(id)sender{
    self.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.5];
}

- (void) transferDidEnd {

    self.progressView.progress = 1.0;
    self.fileInfo.text = [NSString stringWithFormat:@"%@(Finished)",self.fileInfo.text];
}

- (void) transferBegin {
    self.transferSpeed.hidden = NO;
    self.progressView.progress = 0.0;
}

- (void) setProgress: (float)progress {
    self.progressView.progress = progress;
}

- (void) setDynamicTransferSpeed:(NSString*) transferSpeed {
    self.transferSpeed.text = transferSpeed;
}

- (void) setFileSize: (NSString*) fileSize {
    
    // Set the label of file size and status
    if (fileSize.length > 9) {
        fileSize = [NSString stringWithFormat:@"%.2f GB",[fileSize doubleValue] / pow(10, 9.0)];
    } else if(fileSize.length > 6) {
        fileSize = [NSString stringWithFormat:@"%.2f MB",[fileSize doubleValue] / pow(10, 6.0)];
    } else if(fileSize.length > 3) {
        fileSize = [NSString stringWithFormat:@"%.2f KB",[fileSize doubleValue] / pow(10, 3.0)];
    } else {
        fileSize = [NSString stringWithFormat:@"%.2f B",[fileSize doubleValue] ];
    }
    self.fileInfo.text = fileSize;
}

- (void) setFileTitle:(NSString *)title {
    [self setTitle:title forState:UIControlStateNormal];
    
}

@end
