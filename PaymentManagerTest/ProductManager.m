//
//  Product.m
//  PaymentManagerTest
//
//  Created by user on 2014/10/30.
//  Copyright (c) 2014年 yamasaki. All rights reserved.
//

#import "ProductManager.h"

@implementation ProductManager

+ (ProductManager *)sharedInstance {
    static ProductManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[ProductManager alloc] init];
    });
    return _sharedInstance;
}

- (id) init {
    self = [super init];
    
    if (self != nil) {
        // プロダクトID一覧を作成
        _productIds = [[NSMutableSet alloc] init];
        [_productIds addObject:kProductRemoveAd];
        [_productIds addObject:kProductIncreasePoints];
        [_productIds addObject:kProductShowText7days];
        [_productIds addObject:kProductShowText1Month];
        
        // 購入状況をNSUserDefaultsから読み込む
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _isRemoveAd = [_userDefaults boolForKey:kProductRemoveAd];
        _points = [_userDefaults integerForKey:kProductIncreasePoints];
    }
    
    return self;
}

- (void) setIsRemoveiAd:(BOOL)isRemoveAd {
    _isRemoveAd = isRemoveAd;
    // 購入状況をNSUserDefaultsに保存
    [_userDefaults setBool:isRemoveAd forKey:kProductRemoveAd];
    [_userDefaults synchronize];
}

- (void) setPoints:(NSInteger)points {
    _points = points;
    // 購入状況をNSUserDefaultsに保存
    [_userDefaults setInteger:points forKey:kProductIncreasePoints];
    [_userDefaults synchronize];
}


- (BOOL) getIsText {
    // 今現在と有効期限を比較する
    NSNumber *current = [[NSNumber alloc] initWithDouble: [[NSDate date] timeIntervalSince1970]];
    
    NSNumber *expired = [_userDefaults objectForKey:kProductShowTextExpiresDate];
    
    if (expired && NSOrderedDescending != [current compare:expired]) {
        return YES;
    } else {
        return NO;
    }
}

- (int)saveReceipt {
    NSDictionary *dictionary = [[PaymentManager sharedInstance] checkReceipt];
    
    NSNumber *status = [dictionary objectForKey:@"status"];
    
    // ステータスデータの確認
    if (![status isEqual:[NSNumber numberWithInt:0]] &&
        ![status isEqual:[NSNumber numberWithInt:21006]]) {
        NSLog(@"不正なデータ %@", status);
        return [status intValue];
    }
    
    // 定期購読の期限の保存と最新のレシートの保存
    NSDictionary *receiptDictionary = [dictionary objectForKey:@"receipt"];
    NSNumber *experiesDate = [receiptDictionary objectForKey:@"expires_date"];
    NSString *productId = [receiptDictionary objectForKey:@"product_id"];
    
    if (!experiesDate) {
        // リストアの時はexpires_dateキーは存在していないため
        // 期限を設定する必要がある
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSLocale *POSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [formatter setLocale:POSIXLocale];
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *purchaseDate = [formatter dateFromString:[[receiptDictionary objectForKey:@"purchase_date"]
                                                          stringByReplacingOccurrencesOfString:@" Etc/GMT"
                                                          withString:@""]];
        if ([productId isEqualToString:kProductShowText7days]) {
            purchaseDate = [purchaseDate initWithTimeInterval:3600 * 24 * 7 sinceDate:purchaseDate];
        } else if ([productId isEqualToString:kProductShowText1Month]) {
            purchaseDate = [purchaseDate initWithTimeInterval:3600 * 24 * 31 sinceDate:purchaseDate];
        }
        experiesDate = [[NSNumber alloc] initWithDouble:[purchaseDate timeIntervalSince1970]];
    }
    
    if (([productId isEqualToString:kProductShowText7days]) ||
        ([productId isEqualToString:kProductShowText1Month])) {
        [_userDefaults setObject:experiesDate
                          forKey:kProductShowTextExpiresDate];
    }
    return 0;
}


- (void)bought:(NSString *)productIds {
    // 購入されたものをNSUserDefaultsで管理する
    // productIdsでプロダクトを識別
    if ([productIds isEqualToString:kProductRemoveAd]) {
        [self setIsRemoveiAd:YES];
    } else if ([productIds isEqualToString:kProductIncreasePoints]) {
        [self setPoints:_points + 1];
    } else if ([productIds isEqualToString:kProductShowText7days]
               || [productIds isEqualToString:kProductShowText1Month]) {
        // レシート確認
        [self saveReceipt];
    }
}

@end
