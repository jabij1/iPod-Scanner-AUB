//
//  Scan1ViewController.m
//  ScanIT
//
//  Created by Joey Abi Hashim and Carl Bachir on 4/19/14.
//  Copyright (c) 2014 AUB. All rights reserved.
//

#import "HomeViewController.h"
#import "LoginViewController.h"
#import "AppDelegate.h"


@interface HomeViewController ()

@end

@implementation HomeViewController
@synthesize scanButton, suspendDisplayInfo, resultText, resultToken, resultTokenError, supervisor, warningIcon;

bool scanActive = false;
NSTimer *ledTimer = nil;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated
{
	//update display according to current dtdev state
    if(!self.suspendDisplayInfo)
        [self connectionState:scannerDevice.connstate];
    self.suspendDisplayInfo=false;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //initialize dtdev class and connect to it
	scannerDevice = [DTDevices sharedDevice];
	[scannerDevice addDelegate:self];
	[scannerDevice connect];
    
    //intialize login timer
    loginTimer = [[NSTimer alloc] init];
    
    self.suspendDisplayInfo=false;
    scanner1ViewController=self;
	status=[[NSMutableString alloc] init];
	debug=[[NSMutableString alloc] init];
    
#ifdef LOG_FILE
	NSFileManager *fileManger = [NSFileManager defaultManager];
	if ([fileManger fileExistsAtPath:[self getLogFile]])
	{
		[debug appendString:[[NSString alloc] initWithContentsOfFile:[self getLogFile]]];
		[debugText setText:debug];
	}
#endif
    
    //Instantiate app delegate and assign self to delegate's property homeViewController
    AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.homeViewController = self;
    
    //Display supervisor name on top left corner
    [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(displaySupervisor) userInfo:nil repeats:YES];
    
    //Change background color of view to white
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void) viewDidAppear:(BOOL)animated {
    
    //dtdev delegates
    scannerDevice=[DTDevices sharedDevice];
	[scannerDevice addDelegate:self];
    [super viewDidAppear:animated];
   
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    //check if user is logged in
    if(![userDefaults boolForKey:@"loggedIn"]) {
        
        //if user is not logged in, perform segue to login view controller
        LoginViewController* loginViewController = [[LoginViewController alloc] init];
        UIStoryboardSegue* loginSegue = [[UIStoryboardSegue alloc] initWithIdentifier:@"loginSegue" source:self destination:loginViewController];
        [self prepareForSegue:loginSegue sender:self];
        [self performSegueWithIdentifier:@"loginSegue" sender:self];
    }
    
}
-(void) viewDidDisappear:(BOOL)animated
{
    scannerDevice = [DTDevices sharedDevice];
	[scannerDevice removeDelegate:self];
    [super viewDidDisappear:animated];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return NO;
}

//Display the logged in user in the top left corner
-(void) displaySupervisor
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    supervisor.text = [userDefaults valueForKey:@"username"];;
}

- (IBAction)logoutManually:(id)sender
{
    //Change loggedIn variable in standardUserDefaults
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:NO forKey:@"loggedIn"];
    [userDefaults synchronize];
    
    //transition to login view
    [self performSegueWithIdentifier:@"loginSegue" sender:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//This method is called once the barcode is read
-(void)barcodeData:(NSString *)barcode type:(int)type
{
    //send barcode to server to verify
    [self VerifyBarcode:barcode];
}

//This method is called after the barcode is read (inside barcodeData:type). This method connects to the server to verify if student is elligible to vote
-(void) VerifyBarcode:(NSString *)barcode
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    //prepare post data with username and password for connection
    NSString* postInfo =[[NSString alloc] initWithFormat:@"barcode=%@&username=%@&token=%@", barcode, [userDefaults valueForKey:@"username"], [userDefaults valueForKey:@"token"]];
    NSData* postData = [postInfo dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString* postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://192.168.43.92/scan.php"]];
    
    
    
    
    
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    //inform user of connection error
    if(!connection) {
        resultToken.backgroundColor = [UIColor whiteColor];
        resultToken.text = @"Connection Error";
        resultToken.textColor = [UIColor redColor];
        resultToken.font = [UIFont systemFontOfSize:19];
        
        //display and show labels
        warningIcon.hidden = YES;
        resultTokenError.hidden = YES;
        resultToken.hidden = NO;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //get connection data result as JSON, then store as dictionary and get student information
    NSError *error;
    NSDictionary *barcodeResult = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    NSString* message = [barcodeResult valueForKey:@"message"];
    NSString* color = [barcodeResult valueForKey:@"color"];
    int success = [[barcodeResult valueForKey:@"success"] intValue];
    
    //get token color
    NSArray* tokenColorComponents = [color componentsSeparatedByString:@","];
    UIColor* tokenColor = [[UIColor alloc] initWithRed:[tokenColorComponents[0] floatValue] green:[tokenColorComponents[1] floatValue] blue:[tokenColorComponents[2] floatValue] alpha:0.45];
    
    if(success == 1){
        resultToken.font = [UIFont systemFontOfSize:21];
        resultToken.backgroundColor = tokenColor;
        resultToken.textColor = [UIColor blackColor];
        resultToken.text = message;
        warningIcon.hidden = YES;
        
        //display and show labels
        warningIcon.hidden = YES;
        resultTokenError.hidden = YES;
        resultToken.hidden = NO;
    } else if(success == 0) {
        resultTokenError.backgroundColor = [UIColor whiteColor];
        resultTokenError.text = message;
        resultTokenError.textColor = [UIColor redColor];
        resultTokenError.font = [UIFont systemFontOfSize:19];
        
        //display and show labels
        warningIcon.hidden = NO;
        resultTokenError.hidden = NO;
        resultToken.hidden = YES;
    }
    
}

-(NSString *)getLogFile
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"log.txt"];
}

-(void)debug:(NSString *)text
{
	NSDateFormatter *dateFormat=[[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"HH:mm:ss:SSS"];
	NSString *timeString = [dateFormat stringFromDate:[NSDate date]];
	
	if([debug length]>10000)
		[debug setString:@""];
	[debug appendFormat:@"%@-%@\n",timeString,text];
    
#ifdef LOG_FILE
	[debug writeToFile:[self getLogFile]  atomically:YES];
#endif
}

-(void)debugString:(NSString *)text
{
    [self debug:text];
}

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

-(void)ledTimerFunc:object
{
    if(![scannerDevice uiControlLEDsWithBitMask:arc4random() error:nil]) {
        [ledTimer invalidate];
        ledTimer = nil;
    }
}

- (IBAction)scanDown:(id)sender {
    NSError *error=nil;
    
	//[statusImage setImage:[UIImage imageNamed:@"scanning.png"]];
	//[displayText setText:@""];
	//refresh the screen
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    int scanMode;
    
    if([scannerDevice getSupportedFeature:FEAT_LEDS error:nil]==FEAT_SUPPORTED && ledTimer==nil)
    {
        ledTimer=[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(ledTimerFunc:) userInfo:nil repeats:YES];
    }
    
    if([scannerDevice barcodeGetScanMode:&scanMode error:&error] && scanMode==MODE_MOTION_DETECT)
    {
        if(scanActive)
        {
            scanActive=false;
            SHOWERR1([scannerDevice barcodeStopScan:&error]);
        }else {
            scanActive=true;
            SHOWERR1([scannerDevice barcodeStartScan:&error]);
        }
    }else
        SHOWERR1([scannerDevice barcodeStartScan:&error]);
}

- (IBAction)scanUpInside:(id)sender {
    NSError *error;
    
    if([scannerDevice getSupportedFeature:FEAT_LEDS error:nil]==FEAT_SUPPORTED)
    {
        [ledTimer invalidate];
        ledTimer=nil;
        [scannerDevice uiControlLEDsWithBitMask:0 error:nil];
    }
    
    int scanMode;
    
    if([scannerDevice barcodeGetScanMode:&scanMode error:&error] && scanMode!=MODE_MOTION_DETECT)
        SHOWERR1([scannerDevice barcodeStopScan:&error]);
    
    //simulate scan
    [self VerifyBarcode:@"9780262015066"];
}

-(void)connectionState:(int)state {
    //NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    //[dateFormat setDateStyle:kCFDateFormatterLongStyle];
    
    [ledTimer invalidate];
    ledTimer=nil;
    
	switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
			//[statusImage setImage:[UIImage imageNamed:@"disconnected.png"]];
			//[displayText setText:[NSString stringWithFormat:@"Device not connected\nSDK: ver %d.%d (%@)",dtdev.sdkVersion/100,dtdev.sdkVersion%100,[dateFormat stringFromDate:dtdev.sdkBuildDate]]];
			//[batteryButton setHidden:TRUE];
            
			//[_scanButton setHidden:TRUE];
			//[printButton setHidden:TRUE];
			break;
		case CONN_CONNECTED:
            [debug deleteCharactersInRange:NSMakeRange(0,debug.length)];
            //debugText.text=@"";
            scanActive=false;
			//[statusImage setImage:[UIImage imageNamed:@"connected.png"]];
			//[status setString:[NSString stringWithFormat:@"SDK: ver %d.%d (%@)\n%@ %@ connected\nHardware revision: %@\nFirmware revision: %@\nSerial number: %@",dtdev.sdkVersion/100,dtdev.sdkVersion%100,[dateFormat stringFromDate:dtdev.sdkBuildDate],dtdev.deviceName,dtdev.deviceModel,dtdev.hardwareRevision,dtdev.firmwareRevision,dtdev.serialNumber]];
			//[displayText setText:status];
			[scanButton setHidden:FALSE];
            /*
             if([dtdev getSupportedFeature:FEAT_BLUETOOTH error:nil]!=FEAT_UNSUPPORTED)
             [printButton setHidden:FALSE];
             
             [self updateBattery];
             */
            
			break;
	}
    
    
}

-(void)deviceButtonPressed:(int)which {
	[debug setString:@""];
	//[self cleanPrintInfo];
    
    if([scannerDevice getSupportedFeature:FEAT_LEDS error:nil]==FEAT_SUPPORTED && ledTimer==nil)
    {
        ledTimer=[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(ledTimerFunc:) userInfo:nil repeats:YES];
    }
    
	//[displayText setText:@""];
	//[statusImage setImage:[UIImage imageNamed:@"scanning.png"]];
}

-(void)deviceButtonReleased:(int)which
{
    if([scannerDevice getSupportedFeature:FEAT_LEDS error:nil] == FEAT_SUPPORTED) {
        [ledTimer invalidate];
        ledTimer = nil;
        [scannerDevice uiControlLEDsWithBitMask:0 error:nil];
    }
}









@end

