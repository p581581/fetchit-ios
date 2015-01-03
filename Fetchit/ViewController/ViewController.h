//
//  ViewController.h
//  SocketFileTest1
//
//  Created by 581 on 2014/4/15.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import <UIKit/UIKit.h>
#define VIEW_GRADIENT 0.25
#define VIEW_GRADIENT_ALPHA 0.9
#define BUTTON_GRADIENT 0.3
#define BUTTON_GRADIENT_ALPHA 0.9
#define BUTTON_BORDER_WIDTH 0.2
#define BUTTON_BORDER_RADIUS 5


@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *receciveBtn;

@property (weak, nonatomic) IBOutlet UIButton *sendBtn;

+ (void) setViewGradient :(UIView*) view;

@end
