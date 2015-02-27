//
//  LoginViewController.m
//  ScanIT
//
//  Created by Joey Abi Hashim and Carl Bachir on 4/19/14.
//  Copyright (c) 2014 AUB. All rights reserved.
//

#import "LoginViewController.h"
#import "HomeViewController.h"
#import "AppDelegate.h"

@interface LoginViewController ()

@end

@implementation LoginViewController
@synthesize username, password, salt, usernameBox, passwordBox, wrongCredentialsLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    username = nil;
    password = nil;
    salt = @"72to6j";
    usernameBox.delegate = self;
    passwordBox.delegate = self;
    
    //testing only
    AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.loginViewController = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"entered text field did begin editing");
    wrongCredentialsLabel.hidden = YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == usernameBox)
        [passwordBox becomeFirstResponder];
    else if(textField == passwordBox)
        [self login:textField];
    
    return YES;
}

- (IBAction)login:(id)sender {
    NSLog(@"login triggered");
    
    //get username and password from the user, through the text fields.
    username = [NSString stringWithFormat:@"%@", usernameBox.text];
    password = [NSString stringWithFormat:@"%@", passwordBox.text];
    
    //prepare post data with username and password for connection
    NSString* postInfo =[[NSString alloc] initWithFormat:@"username=%@&password=%@&salt=%@", username, password, salt];
    NSData* postData = [postInfo dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString* postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://192.168.43.92/home/login.php"]];
    //
    
    
    
    
    
    
    
    
    
    
    
    
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(!connection) {
        wrongCredentialsLabel.hidden = false;
        wrongCredentialsLabel.text = @"Connection Not Available";
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"did receive data");
    
    //get NSUserDefault variable to change login status
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    //get barcode result as a JSON object and then store it as a dictionary. Then get student information
    NSError* error;
    NSDictionary* barcodeResult = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    int success = [[barcodeResult valueForKey:@"success"] intValue]; //to check if the login is successful
    
    //save token to NSUserDefaults
    [userDefaults setValue:[barcodeResult valueForKey:@"token"] forKey:@"token"];
    
    //check login
    if(success == 1) {
        
        //indicate in NSUserDefaults that the user is logged in, and who the user is
        [userDefaults setBool:YES forKey:@"loggedIn"];
        [userDefaults setValue:username forKey:@"username"];
        [userDefaults synchronize];
        
        //dismiss login view controller
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } else if(success == 0) {
        wrongCredentialsLabel.hidden = false;
        wrongCredentialsLabel.text = @"Wrong username or password. Please try again.";
    }
    
}

//Not used anymore
- (void)simulateDidReceiveData
{
    NSLog(@"did receive data");
    
    //get NSUserDefault variable to change login status
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    //get username and password from the user, through the text fields.
    username = [NSString stringWithFormat:@"%@", usernameBox.text];
    password = [NSString stringWithFormat:@"%@", passwordBox.text];
    
    int success = 0;
    
    //simulate success
    if([username isEqualToString:@"c"] && [password isEqualToString:@"1"])
        success = 1;
    
    if(success == 1) {
        [userDefaults setBool:YES forKey:@"loggedIn"];
        [userDefaults synchronize];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if(success == 0) {
        wrongCredentialsLabel.hidden = false;
    }
}


@end
