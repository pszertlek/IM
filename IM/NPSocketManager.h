//
//  NPSocketManager.h
//  IM
//
//  Created by apple on 2017/12/12.
//  Copyright © 2017年 Pszertlek. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NPSocketManager : NSObject

+ (instancetype)shared;

- (void)connect;

- (void)disconnect;

- (void)sendMsg:(NSString *)msg;

@end
