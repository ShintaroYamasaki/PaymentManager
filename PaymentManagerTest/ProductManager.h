//
//  Product.h
//  PaymentManagerTest
//
//  Created by user on 2014/10/30.
//  Copyright (c) 2014年 yamasaki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PaymentManager.h"

// プロダクトID
#define kProductRemoveAd @"jp.cubic.PaymentManagerTest.removeAd"
#define kProductIncreasePoints @"jp.cubic.PaymentManagerTest.addPoints"
#define kProductShowTextExpiresDate @"ShowTextExpiresDate"
#define kProductShowText7days @"jp.cubic.PaymentManagerTest.ShowText7days"
#define kProductShowText1Month @"jp.cubic.PaymentManagerTest.ShowText1Month"

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
/** 購読テキスト表示/非表示 */
@property (nonatomic) BOOL isText;


+ (ProductManager *)sharedInstance;
/** 購入の反映 */
- (void)bought:(NSString *)productIds;
@end
