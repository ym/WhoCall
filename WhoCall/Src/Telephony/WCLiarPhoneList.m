//
//  WCLiarPhoneList.m
//  WhoCall
//
//  Created by Wang Xiaolei on 10/1/13.
//  Copyright (c) 2013 Wang Xiaolei. All rights reserved.
//

#import "WCLiarPhoneList.h"

@interface WCLiarPhoneList ()

@property (strong, nonatomic) NSCache *cache;

@end

@implementation WCLiarPhoneList

+ (instancetype)sharedList
{
    static WCLiarPhoneList *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WCLiarPhoneList alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

- (void)checkLiarNumber:(NSString *)phoneNumber
         withCompletion:(void(^)(NSString *liarInfo))completion
{
    // 测试：
//    phoneNumber = @"01053202011";   // 广告
//    phoneNumber = @"15306537056";   // 快递
    
    NSString *cachedInfo = [self.cache objectForKey:phoneNumber];
    if (cachedInfo && completion) {
        completion(cachedInfo);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *escaped = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (__bridge CFStringRef)phoneNumber,
                                                                                                  NULL,
                                                                                                  CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                                  kCFStringEncodingUTF8));
        NSURL *searchURL = [NSURL URLWithString:[@"https://tool.moease.org/lookup.php?num=" stringByAppendingString:escaped]];
        NSString *searchResult = [NSString stringWithContentsOfURL:searchURL
                                                          encoding:NSUTF8StringEncoding
                                                             error:NULL];
        
        [self.cache setObject:searchResult forKey:phoneNumber];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(searchResult);
            });
        }
    });
}

@end
