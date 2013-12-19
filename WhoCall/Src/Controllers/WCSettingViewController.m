//
//  WCSettingViewController.m
//  WhoCall
//
//  Created by Wang Xiaolei on 11/17/13.
//  Copyright (c) 2013 Wang Xiaolei. All rights reserved.
//

@import AddressBook;
#import "WCSettingViewController.h"
#import "WCCallInspector.h"
#import "WCAddressBook.h"
#import "UIAlertView+MKBlockAdditions.h"

@interface WCSettingViewController ()

@end

@implementation WCSettingViewController

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
    
    self.navigationItem.backBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@""
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
    
    WCCallInspector *inspector = [WCCallInspector sharedInspector];
    self.switchLiar.on = inspector.handleLiarPhone;
    self.switchLocation.on = inspector.handlePhoneLocation;
}

- (void)viewDidAppear:(BOOL)animated {
    // 触发弹出通讯录授权，第一次启动app后就弹出，避免在第一次来电的时候才弹
    [WCAddressBook defaultAddressBook];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)onSettingValueChanged:(UISwitch *)sender
{
    WCCallInspector *inspector = [WCCallInspector sharedInspector];
    if (sender == self.switchLiar) {
        inspector.handleLiarPhone = sender.on;
    } else if (sender == self.switchLocation) {
        inspector.handlePhoneLocation = sender.on;
    }
    [inspector saveSettings];
}

@end
