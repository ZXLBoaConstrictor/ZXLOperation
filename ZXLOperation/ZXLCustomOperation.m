//
//  ZXLCustomOperation.m
//  ZXLOperation
//
//  Created by 张小龙 on 2018/4/28.
//  Copyright © 2018年 张小龙. All rights reserved.
//

#import "ZXLCustomOperation.h"
#import "ZXLOperationQueueManager.h"

static NSString * const ZXLCompressOperationLockName = @"ZXLCompressOperationLockName";

@interface ZXLCustomOperation()
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic,strong)NSHashTable * tableCallback;
@end


@implementation ZXLCustomOperation
@synthesize executing = _executing;
@synthesize finished  = _finished;
@synthesize cancelled = _cancelled;

-(instancetype)init{
    if (self = [super init]) {
        self.lock = [[NSRecursiveLock alloc] init];
        self.lock.name = ZXLCompressOperationLockName;
    }
    return self;
}

-(NSHashTable *)tableCallback{
    if (!_tableCallback) {
        _tableCallback = [NSHashTable hashTableWithOptions:NSHashTableCopyIn];
    }
    return _tableCallback;
}

- (void)addCallback:(ZXLCallback)callback{
    if (callback) {
        [self.tableCallback addObject:callback];
    }
}

#pragma mark - operation
- (void)cancel {
    [self.lock lock];
    if (!self.isCancelled && !self.isFinished) {
        [super cancel];
        [self KVONotificationWithNotiKey:@"isCancelled" state:&_cancelled stateValue:YES];
        if (self.isExecuting) {
            //已经开始停止任务
            [self runSelector:@selector(cancelToDoSth)];
        }else{
            //未开始清空数据
            [self runSelector:@selector(clearOperation)];
        }
    }
    [self.lock unlock];
    [self finish];
}

/**
 取消任务
 */
-(void)cancelToDoSth{
    
}

//清空任务
-(void)clearOperation{
    
}

- (void)start {
    [self.lock lock];
    if (self.isCancelled) {
        [self finish];
        [self.lock unlock];
        return;
    }
    if (self.isFinished || self.isExecuting) {
        [self.lock unlock];
        return;
    }
    
    [self runSelector:@selector(startToDoSth)];
    
    [self.lock unlock];
}

//开始任务
- (void)startToDoSth {
    if (self.isCancelled || self.isFinished || self.isExecuting) {
        return;
    }
    
    [self KVONotificationWithNotiKey:@"isExecuting" state:&_executing stateValue:YES];

    //开始做一些耗时、耗性能、耗内存等一些操作
    //....
    
    //处理返回
    for (ZXLCallback callback in self.tableCallback) {
        if (callback) {
            callback(YES);
        }
    }
    //执行完成后结束
    [self finish];
}

- (void)finish {
    [self.lock lock];
    if (self.isExecuting) {
        [self KVONotificationWithNotiKey:@"isExecuting" state:&_executing stateValue:NO];
    }
    [self KVONotificationWithNotiKey:@"isFinished" state:&_finished stateValue:YES];
    [self.lock unlock];
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)KVONotificationWithNotiKey:(NSString *)key state:(BOOL *)state stateValue:(BOOL)stateValue {
    [self.lock lock];
    [self willChangeValueForKey:key];
    *state = stateValue;
    [self didChangeValueForKey:key];
    [self.lock unlock];
}

- (void)runSelector:(SEL)selecotr {
    [self performSelector:selecotr onThread:[ZXLOperationQueueManager customOperationThread] withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
}

@end
