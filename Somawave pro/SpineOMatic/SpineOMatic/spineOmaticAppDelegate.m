//
//  spineOmaticAppDelegate.m
//  SpineOMatic
//
//  Created by Bhaskar Jyoti Das on 07/10/13.
//  Copyright (c) 2013 Bhaskar Jyoti Das. All rights reserved.
//

#import "spineOmaticAppDelegate.h"

@implementation spineOmaticAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunchingWithOptions");
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    NSMutableDictionary *noteDictionary = [[NSMutableDictionary alloc]initWithObjectsAndKeys:
                                           @"C1",@"32.7",
                                           @"C#1",@"34.65",
                                           @"D1",@"36.71",
                                           @"D#1", @"38.89",
                                           @"E1",@"41.2",
                                           @"F1",@"43.65",
                                           @"F#1",@"46.25",
                                           @"G1",@"49",
                                           @"G#1",@"51.91",
                                           @"A1",@"55",
                                           @"A#1",@"58.27",
                                           @"B1",@"61.74",
                                           @"C2",@"65.41",
                                           @"C#2",@"69.3",
                                           @"D2",@"73.42",
                                           @"D#2",@"77.78",
                                           @"E2",@"82.41",
                                           @"F2",@"87.31",
                                           @"F#2",@"92.5",
                                           @"G2",@"98",
                                           @"G#2",@"103.83",
                                           @"A2",@"110",
                                           @"A#2",@"116.54",
                                           @"B2",@"123.47",
                                           @"C3",@"130.81",
                                           @"C#3",@"138.59",
                                           @"D3",@"146.83",
                                           @"D#3",@"155.56",
                                           @"E3",@"164.81",
                                           @"F3",@"174.61",
                                           @"F#3",@"185",
                                           @"G3",@"196",
                                           @"G#3",@"207.65",
                                           @"A3",@"220",
                                           @"A#3",@"233.08",
                                           @"B3",@"246.94", nil];
    NSMutableDictionary *hertzDictionary = [[NSMutableDictionary alloc]initWithObjectsAndKeys:
                                            @"32.7",@"C1",
                                            @"34.65",@"C#1",
                                            @"36.71",@"D1",
                                            @"38.89", @"D#1",
                                            @"41.2",@"E1",
                                            @"43.65",@"F1",
                                            @"46.25",@"F#1",
                                            @"49",@"G1",
                                            @"51.91",@"G#1",
                                            @"55",@"A1",
                                            @"58.27",@"A#1",
                                            @"61.74",@"B1",
                                            @"65.41", @"C2", //65.41
                                            @"69.3",@"C#2",
                                            @"73.42",@"D2",
                                            @"77.78",@"D#2",
                                            @"82.41",@"E2",
                                            @"87.31",@"F2",
                                            @"92.5",@"F#2",
                                            @"98",@"G2",
                                            @"103.83",@"G#2",
                                            @"110",@"A2",
                                            @"116.54",@"A#2",
                                            @"123.47",@"B2",
                                            @"130.81",@"C3",
                                            @"138.59",@"C#3",
                                            @"146.83",@"D3",
                                            @"155.56",@"D#3",
                                            @"164.81",@"E3",
                                            @"174.61",@"F3",
                                            @"185",@"F#3",
                                            @"196",@"G3",
                                            @"207.65",@"G#3",
                                            @"220",@"A3",
                                            @"233.08",@"A#3",
                                            @"246.94",@"B3", nil];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:noteDictionary,@"note",hertzDictionary,@"hertz", nil];
    NSLog(@"middle");
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"SharpDictionary"];
    NSMutableDictionary *noteDictionaryB = [[NSMutableDictionary alloc]initWithObjectsAndKeys:
                                            @"C1",@"32.7",
                                            @"Db1",@"34.65",
                                            @"D1",@"36.71",
                                            @"Eb1", @"38.89",
                                            @"E1",@"41.2",
                                            @"F1",@"43.65",
                                            @"Gb1",@"46.25",
                                            @"G1",@"49",
                                            @"Ab1",@"51.91",
                                            @"A1",@"55",
                                            @"Bb1",@"58.27",
                                            @"B1",@"61.74",
                                            @"C2",@"65.41",
                                            @"Db2",@"69.3",
                                            @"D2",@"73.42",
                                            @"Eb2",@"77.78",
                                            @"E2",@"82.41",
                                            @"F2",@"87.31",
                                            @"Gb2",@"92.5",
                                            @"G2",@"98",
                                            @"Ab2",@"103.83",
                                            @"A2",@"110",
                                            @"Bb2",@"116.54",
                                            @"B2",@"123.47",
                                            @"C3",@"130.81",
                                            @"Db3",@"138.59",
                                            @"D3",@"146.83",
                                            @"Eb3",@"155.56",
                                            @"E3",@"164.81",
                                            @"F3",@"174.61",
                                            @"Gb3",@"185",
                                            @"G3",@"196",
                                            @"Ab3",@"207.65",
                                            @"A3",@"220",
                                            @"Bb3",@"233.08",
                                            @"B3",@"246.94", nil];
    NSMutableDictionary *hertzDictionaryB = [[NSMutableDictionary alloc]initWithObjectsAndKeys:
                                             @"32.7",@"C1",
                                             @"34.65",@"Db1",
                                             @"36.71",@"D1",
                                             @"38.89", @"Eb1",
                                             @"41.2",@"E1",
                                             @"43.65",@"F1",
                                             @"46.25",@"Gb1",
                                             @"49",@"G1",
                                             @"51.91",@"Ab1",
                                             @"55",@"A1",
                                             @"58.27",@"Bb1",
                                             @"61.74",@"B1",
                                             @"65.41", @"C2",
                                             @"69.3",@"Db2",
                                             @"73.42",@"D2",
                                             @"77.78",@"Eb2",
                                             @"82.41",@"E2",
                                             @"87.31",@"F2",
                                             @"92.5",@"Gb2",
                                             @"98",@"G2",
                                             @"103.83",@"Ab2",
                                             @"110",@"A2",
                                             @"116.54",@"Bb2",
                                             @"123.47",@"B2",
                                             @"130.81",@"C3",
                                             @"138.59",@"Db3",
                                             @"146.83",@"D3",
                                             @"155.56",@"Eb3",
                                             @"164.81",@"E3",
                                             @"174.61",@"F3",
                                             @"185",@"Gb3",
                                             @"196",@"G3",
                                             @"207.65",@"Ab3",
                                             @"220",@"A3",
                                             @"233.08",@"Bb3",
                                             @"246.94",@"B3", nil];
    NSMutableDictionary *dict1 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:noteDictionaryB,@"note",hertzDictionaryB,@"hertz", nil];
    [[NSUserDefaults standardUserDefaults] setObject:dict1 forKey:@"BDictionary"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"rootViewController"];
    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:vc];
     [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
