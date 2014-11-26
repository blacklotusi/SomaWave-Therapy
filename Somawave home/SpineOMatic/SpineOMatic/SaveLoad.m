//
//  SaveLoad.m
//  SpineOMatic
//
//  Created by Bhaskar Jyoti Das on 12/11/13.
//  Copyright (c) 2013 Bhaskar Jyoti Das. All rights reserved.
//

#import "SaveLoad.h"

@implementation SaveLoad
+(void)SaveSlotNo:(NSString *)slotName BankNo:(NSString *)bankName information:(NSMutableDictionary *)detail{
    NSMutableDictionary *storeDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] valueForKey:@"Store"]];
    if(storeDict == nil){
        storeDict = [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *bankDict = [NSMutableDictionary dictionaryWithDictionary:[storeDict objectForKey:bankName]];
    if(bankDict == nil){
        bankDict = [[NSMutableDictionary alloc] init];
    }
    [bankDict setObject:detail forKey:slotName];
    [storeDict setObject:bankDict forKey:bankName];
    [[NSUserDefaults standardUserDefaults] setObject:storeDict forKey:@"Store"];
    NSLog(@"save details %@",detail);
}

+(NSMutableDictionary *)LoadDetailsSlotNo:(NSString *)slotName BankNo:(NSString *)bankName{
    
    NSMutableDictionary *storeDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] valueForKey:@"Store"]];
    if(storeDict != nil){
        NSMutableDictionary *bankDict = [NSMutableDictionary dictionaryWithDictionary:[storeDict objectForKey:bankName]];
        if(bankDict != nil){
            NSMutableDictionary *slotDict = [NSMutableDictionary dictionaryWithDictionary:[bankDict objectForKey:slotName]];
            if (slotDict!=nil) {
                return slotDict;
            }else
                return nil;
        }else
            return nil;
    }else
        return nil;
}
@end
