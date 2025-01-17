#import "MessageAdapter.h"

@implementation MessageAdapter

- (instancetype)init {
    self = [super init];
    if (self) {
        _messages = [NSMutableArray array];
    }
    return self;
}

- (void)addMessage:(Message *)message {
    [self.messages addObject:message];
}

- (void)updateMessage:(Message *)message {
    NSInteger index = [self.messages indexOfObject:message];
    if (index != NSNotFound) {
        [self.messages replaceObjectAtIndex:index withObject:message];
    }
}

- (void)removeMessage:(Message *)message {
    [self.messages removeObject:message];
}

- (NSArray<Message *> *)getMessages {
    return [self.messages copy];
}

- (void)clear {
    [self.messages removeAllObjects];
}

@end
