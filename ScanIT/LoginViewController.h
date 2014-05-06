//
//  LoginViewController.h
//  ScanIT
//
//  Created by Joey Abi Hashim and Carl Bachir on 4/19/14.
//  Copyright (c) 2014 AUB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController<NSURLConnectionDataDelegate, UITextFieldDelegate>
{
    NSString* username;
    NSString* password;
}

@property NSString* username;
@property NSString* password;

@property (strong, nonatomic) IBOutlet UITextField *usernameBox;
@property (strong, nonatomic) IBOutlet UITextField *passwordBox;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *wrongCredentialsLabel;

- (IBAction)login:(id)sender;

@end
