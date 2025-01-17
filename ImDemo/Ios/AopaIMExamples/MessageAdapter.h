#import <Foundation/Foundation.h>
#import "AopaImModels.h"

@interface MessageAdapter : NSObject

@property (nonatomic, strong) NSMutableArray<Message *> *messages;

- (void)addMessage:(Message *)message;
- (void)updateMessage:(Message *)message;
- (void)removeMessage:(Message *)message;
- (NSArray<Message *> *)getMessages;
- (void)clear;

@end
