//
//  ZXLOperationQueueManager.h
//  ZXLOperation
//
//  Created by 张小龙 on 2018/4/28.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZXLOperationQueueManager : NSObject
+(instancetype)manager;
+(NSThread *)customOperationThread;

//取消所有操作
- (void)cancelOperations;
//取消单个操作
-(void)cancelOperationForIdentifier:(NSString *)identifier;

//运用场景例子1 大量视频压缩、多图片处理、文件压缩等，同文件等待block返回
-(void)addCompress:(NSString *)filePath comlpate:(void (^)(BOOL bResult))comlpate;

//运用场景例子2 大量文件上传，同文件等待block返回
-(void)addUpload:(NSString *)filePath comlpate:(void (^)(BOOL bResult))comlpate;
//......还有很多运用场景

@end
