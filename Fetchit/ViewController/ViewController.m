//
//  ViewController.m
//  SocketFileTest1
//
//  Created by 581 on 2014/4/15.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import "ViewController.h"
@interface ViewController ()
@end

@implementation ViewController

+ (void) setViewGradient :(UIView*) view{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = view.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:VIEW_GRADIENT green:VIEW_GRADIENT blue:VIEW_GRADIENT alpha:VIEW_GRADIENT_ALPHA  ] CGColor], (id)[[UIColor blackColor] CGColor], nil]; // 由上到下的漸層顏色
    [view.layer insertSublayer:gradient atIndex:0];
}

+ (void) setButtonStyle: (UIButton*) button {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient = [CAGradientLayer layer];
    gradient.frame = button.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:BUTTON_GRADIENT green:BUTTON_GRADIENT blue:BUTTON_GRADIENT alpha:BUTTON_GRADIENT_ALPHA  ] CGColor], (id)[[UIColor blackColor] CGColor], nil]; // 由上到下的漸層顏色
    [button.layer insertSublayer:gradient atIndex:0];
    button.layer.borderColor = [[UIColor whiteColor] CGColor];
    button.layer.borderWidth = BUTTON_BORDER_WIDTH;
    button.layer.cornerRadius = BUTTON_BORDER_RADIUS;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //設定主畫面漸層
    [ViewController setViewGradient:self.view];
    
    //設定傳送按鈕漸層和border
    [ViewController setButtonStyle:self.sendBtn];
    
    //設定接收按鈕漸層和border
    [ViewController setButtonStyle:self.receciveBtn];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
