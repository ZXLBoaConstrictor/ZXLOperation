//
//  ZXLCustomOperation.h
//  ZXLOperation
//
//  Created by 张小龙 on 2018/4/28.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>

//为了例子自定义了一个Callback 实际使用可以自己根据需要创建callback
typedef void (^ZXLCallback)(BOOL bResult);

@interface ZXLCustomOperation : NSOperation
@property (nonatomic, copy) NSString *identifier;

- (void)addCallback:(ZXLCallback)callback;
@end
