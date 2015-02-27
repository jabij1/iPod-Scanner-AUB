//
//  AppDelegate.m
//  ScanIT
//
//  Created by Joey Abi Hashim and Carl Bachir on 4/19/14.
//  Copyright (c) 2014 AUB. All rights reserved.
//

#import "AppDelegate.h"
#import "HomeViewController.h"
#import "LoginViewController.h"

@implementation AppDelegate
@synthesize homeViewController, loginViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    //start logout timer. After 10 min of user inactivity, logout user
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(logout) userInfo:nil repeats:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    //get standardUserDefaults to check if user is logged in (session is still active)
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    //check if user is logged in
    if(![userDefaults boolForKey:@"loggedIn"]) {
        
        //present login view controller modally
        [homeViewController performSegueWithIdentifier:@"loginSegue" sender:self];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    //logout current user by modifying login status in NSUserDefaults
    [self logout];
}

//Logout the user. This method is called 10 minutes after the timer fires in applicationDidEnterBackground
-(void) logout
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:NO forKey:@"loggedIn"];
    [userDefaults synchronize];

}

@end
