//
//  ZXLOperationQueueManager.m
//  ZXLOperation
//
//  Created by 张小龙 on 2018/4/28.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLOperationQueueManager.h"
#import "ZXLCustomOperation.h"

#define ZXLMaxConcurrentOperationCount 3 //控制执行数量

@interface ZXLOperationQueueManager ()
@property (nonatomic, strong) dispatch_queue_t addOperationSerialQueue;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSThread* operationThread; //控制cup性能
@end

@implementation ZXLOperationQueueManager
+(instancetype)manager{
    static dispatch_once_t pred = 0;
    __strong static ZXLOperationQueueManager * _manager = nil;
    dispatch_once(&pred, ^{
        _manager = [[ZXLOperationQueueManager alloc] init];
    });
    return _manager;
}

-(dispatch_queue_t)addOperationSerialQueue{
    if (!_addOperationSerialQueue) {
        _addOperationSerialQueue = dispatch_queue_create("com.zxl.ZXLOperationQueueManagerAddOperationSerializeQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _addOperationSerialQueue;
}

-(NSOperationQueue *)operationQueue{
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = ZXLMaxConcurrentOperationCount;
        [_operationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    }
    return _operationQueue;
}

-(NSThread *)operationThread{
    if (!_operationThread) {
        _operationThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadEntryPoint:) object:nil];
    }
    return _operationThread;
}

- (void)threadEntryPoint:(id)__unused object {
    @autoreleasepool {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    //当operationCount 为0的时候释放
    if (object == self.operationQueue && self.operationQueue.operationCount == 0) {
        [self.operationThread cancel];
        self.operationThread = nil;
    }
}

#pragma mark - cancel
- (void)cancelOperations {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.operationQueue cancelAllOperations];
    });
}

-(void)cancelOperationForIdentifier:(NSString *)identifier{
    ZXLCustomOperation * operation = [self checkFile:identifier];
    if (operation && ![operation isCancelled]) {
        [operation cancel];
    }
}

+(NSThread *)customOperationThread{
    return [ZXLOperationQueueManager manager].operationThread;
}

- (ZXLCustomOperation *)checkFile:(NSString *)identifier {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    NSArray *filterResult = [self.operationQueue.operations filteredArrayUsingPredicate:predicate];
    if (filterResult.count > 0) {
        return (ZXLCustomOperation *)[filterResult firstObject];
    }
    return nil;
}

-(void)addCompress:(NSString *)filePath comlpate:(void (^)(BOOL bResult))comlpate{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.addOperationSerialQueue, ^{
        //这里把文件地址作为了identifier 实际使用的时候可以拿文件的MD5值或者相册文件的assetLocalIdentifier的MD5 等信息作为 identifier
        ZXLCustomOperation *operation = [weakSelf checkFile:filePath];
        if (!operation) {
            operation =  [[ZXLCustomOperation alloc] init];
            operation.identifier = filePath;
            [weakSelf.operationQueue addOperation:operation];
        }
        [operation addCallback:comlpate];
    });
}


-(void)addUpload:(NSString *)filePath comlpate:(void (^)(BOOL bResult))comlpate{
    //实现和上面的代码基本一样
}
@end
