//
//  SecurityPinManager.h
//  EnFile
//
//  Created by Phil on 2018/10/22.
//  Copyright © 2018年 Senao. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SecurityResultType){
    Created,
    Verified,
    Changed
};

typedef void (^ResultBlock)(SecurityResultType type);

@interface SecurityPinManager : NSObject

@property (nonatomic, strong, readonly) NSString *pinCode;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

+ (instancetype)sharedInstance;

- (void)removePinCode;

- (void)presentSecurityPinViewControllerForChangePasscodeWithAnimated: (BOOL)flag completion:(void (^ __nullable)(void))completion result:(ResultBlock _Nullable )result;
//- (void)presentSecurityPinViewControllerWithAnimated: (BOOL)flag completion:(void (^ __nullable)(void))completion;
- (void)presentSecurityPinViewControllerForCreateWithAnimated: (BOOL)flag completion:(void (^ __nullable)(void))completion result:(ResultBlock _Nullable )result;
- (void)presentSecurityPinViewControllerForRemoveWithAnimated: (BOOL)flag completion:(void (^ __nullable)(void))completion result:(ResultBlock _Nullable )result;
- (void)presentSecurityPinViewControllerForUnlockWithAnimated: (BOOL)flag completion:(void (^ __nullable)(void))completion result:(ResultBlock _Nullable )result;
@end
