//
//  SaveLoad.h
//  SpineOMatic
//
//  Created by Bhaskar Jyoti Das on 12/11/13.
//  Copyright (c) 2013 Bhaskar Jyoti Das. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SaveLoad : NSObject

+(void)SaveSlotNo : (NSString *)slotName BankNo : (NSString *)bankName information : (NSMutableDictionary *) detail;
+(NSMutableDictionary *)LoadDetailsSlotNo : (NSString *)slotName BankNo : (NSString *)bankName;
@end
