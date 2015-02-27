//
//  Scan1ViewController.h
//  ScanIT
//
//  Created by Joey Abi Hashim and Carl Bachir on 4/19/14.
//  Copyright (c) 2014 AUB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTDevices.h"

@class HomeViewController;

@protocol Scan1Delegate

-(void)backToOriginalButtonClicked:(HomeViewController*)scan1VC;

@end



@interface HomeViewController : UIViewController <DTDeviceDelegate, UITextFieldDelegate, NSURLConnectionDataDelegate, UIWebViewDelegate>
{
    NSMutableString *status;
    NSMutableString *debug;
    NSTimer* loginTimer;
    
    DTDevices *scannerDevice;
}

@property (weak, nonatomic) id<Scan1Delegate> delegate;
@property (assign) bool suspendDisplayInfo;
@property (strong, nonatomic) IBOutlet UIImageView *warningIcon;
@property (weak, nonatomic) IBOutlet UILabel *resultText;
@property (strong, nonatomic) IBOutlet UILabel *resultToken;
@property (strong, nonatomic) IBOutlet UILabel *resultTokenError;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (strong, nonatomic) IBOutlet UILabel *supervisor;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;

-(void)debug:(NSString *)text;
- (IBAction)scanDown:(id)sender;
- (IBAction)scanUpInside:(id)sender;
- (IBAction)logoutManually:(id)sender;

@end

HomeViewController *scanner1ViewController;

#define SHOWERR1(func) func; if(error)[scanner1ViewController debug:error.localizedDescription];
#define ERRMSG(title) {UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil]; [alert show];}

