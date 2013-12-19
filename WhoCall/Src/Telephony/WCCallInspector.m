//
//  WCCallInspector.m
//  WhoCall
//
//  Created by Wang Xiaolei on 11/18/13.
//  Copyright (c) 2013 Wang Xiaolei. All rights reserved.
//

@import AVFoundation;
@import AudioToolbox;
#import "WCCallInspector.h"
#import "WCCallCenter.h"
#import "WCAddressBook.h"
#import "WCLiarPhoneList.h"
#import "WCPhoneLocator.h"


// 保存设置key
#define kSettingKeyLiarPhone        @"com.wangxl.WhoCall.HandleLiarPhone"
#define kSettingKeyPhoneLocation    @"com.wangxl.WhoCall.HandlePhoneLocation"


@interface WCCallInspector ()

@property (nonatomic, strong) WCCallCenter *callCenter;
@property (nonatomic, copy) NSString *incomingPhoneNumber;
@property (nonatomic, strong) UILocalNotification *notification;

@end


@implementation WCCallInspector

+ (instancetype)sharedInspector
{
    static WCCallInspector *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WCCallInspector alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self loadSettings];
    }
    return self;
}

- (void)startInspect
{
    if (self.callCenter) {
        return;
    }
    
    self.callCenter = [[WCCallCenter alloc] init];
    
    __weak WCCallInspector *weakSelf = self;
    self.callCenter.callEventHandler = ^(WCCall *call) { [weakSelf handleCallEvent:call]; };
}

- (void)stopInspect
{
    self.callCenter = nil;
}

- (void)handleCallEvent:(WCCall *)call {
    // 接通后震动一下（防辐射，你懂的）
    if (call.callStatus == kCTCallStatusConnected) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        return;
    }

    // 来电挂断就把通知給取消掉
    if (call.callStatus != kCTCallStatusCallIn) {
        self.incomingPhoneNumber = nil;
        if(self.notification) {
            [[UIApplication sharedApplication] cancelLocalNotification:self.notification];
        }
        return;
    }
    
    // 以下皆为来电状态处理
    NSString *number = call.phoneNumber;
    self.incomingPhoneNumber = number;
    
    BOOL isContact = [[WCAddressBook defaultAddressBook] isContactPhoneNumber:number];
    
    // 检查归属地
    void (^checkPhoneLocation)(void) = ^{
        if (self.handlePhoneLocation && !isContact) {
            NSString *location = [[WCPhoneLocator sharedLocator] locationForPhoneNumber:number];
            if (location) {
                // 注意格式，除了地址，还可以有“本地”等
                [self notifyMessage: location];
            }
        }
    };
    
    // 欺诈电话联网查，等待查询结束才能知道要不要提示地点
    if (self.handleLiarPhone && !isContact) {
        [[WCLiarPhoneList sharedList] checkLiarNumber:number withCompletion:^(NSString *liarInfo) {
            if (liarInfo.length != 0) {
                [self notifyMessage: liarInfo];
            } else {
                checkPhoneLocation();
            }
        }];
    } else {
        checkPhoneLocation();
    }
}

- (void)loadSettings
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    if ([def objectForKey:kSettingKeyLiarPhone]) {
        self.handleLiarPhone = [def boolForKey:kSettingKeyLiarPhone];
        self.handlePhoneLocation = [def boolForKey:kSettingKeyPhoneLocation];
    } else {
        // 第一次初始化
        self.handleLiarPhone = YES;
        self.handlePhoneLocation = YES;
    }
}

- (void)saveSettings
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setBool:self.handleLiarPhone forKey:kSettingKeyLiarPhone];
    [def setBool:self.handlePhoneLocation forKey:kSettingKeyPhoneLocation];
    [def synchronize];
}

- (void)notifyMessage:(NSString *)text {
    if (text.length == 0) {
        return;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.notification = [[UILocalNotification alloc] init];
    });
    
    self.notification.alertAction = @"Done";
    self.notification.alertBody = text;
    self.notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    self.notification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:self.notification];
}

- (void)stopSpeakText {

}

@end
