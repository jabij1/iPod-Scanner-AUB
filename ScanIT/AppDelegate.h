//
//  AppDelegate.h
//  ScanIT
//
//  Created by Joey Abi Hashim and Carl Bachir on 4/19/14.
//  Copyright (c) 2014 AUB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//testing only
@property (weak, nonatomic) UIViewController* loginViewController;
@property (weak, nonatomic) UIViewController* homeViewController;

@end
