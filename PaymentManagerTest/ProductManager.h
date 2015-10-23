//
//  Product.h
//  PaymentManagerTest
//
//  Created by user on 2014/10/30.
//  Copyright (c) 2014年 yamasaki. All rights reserved.
//

#import <Foundation/Foundation.h>

// プロダクトID
#define kProductRemoveAd @"jp.cubic.PaymentManagerTest.removeAd"
#define kProductIncreasePoints @"jp.cubic.PaymentManagerTest.addPoints"
#define kProductShowTest7days @"jp.cubic.PaymentManagerTest.ShowText7days"

/** プロダクト管理クラス */
@interface ProductManager : NSObject {
    NSUserDefaults *_userDefaults;
}

/** プロダクトID一覧 */
@property (nonatomic, readonly) NSMutableSet *productIds;
/** 広告の表示/非表示 */
@property (nonatomic) BOOL isRemoveAd;
/** ポイント数 */
@property (nonatomic) NSInteger points;


+ (ProductManager *)sharedInstance;
/** 購入の反映 */
- (void)bought:(NSString *)productIds;
@end
