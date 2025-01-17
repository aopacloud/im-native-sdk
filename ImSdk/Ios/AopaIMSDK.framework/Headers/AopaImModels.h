#import <Foundation/Foundation.h>
#import "AopaImTypes.h"


@interface Message : NSObject
@property (nonatomic, copy) NSString *messageId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, assign) MessageType type;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, assign) DirectionType direction;
@property (nonatomic, assign) MessageStatus status;
@property (nonatomic, assign) BOOL isRead;
@property (nonatomic, assign) BOOL isRecalled;
@property (nonatomic, assign) NSInteger duration;  // 语音消息时长
- (instancetype)initWithType:(MessageType)type content:(NSString *)content messageId:(NSString *)messageId  userId:(NSString *)userId;
@end

@interface SendUser : NSObject
@property(nonatomic, assign) uint32_t userId;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *portraitUri;
@end

@interface ConversationLastMessage : NSObject
@property(nonatomic, assign) int messageId;
@property(nonatomic, assign) MessageType type;
@property(nonatomic, copy) NSString *content;
@property(nonatomic, strong) SendUser *user;
@property(nonatomic, copy) NSString *extra;
@end

@interface Conversation : NSObject
@property(nonatomic, assign) ConversationType type;
@property(nonatomic, assign) uint32_t targetId;
@property(nonatomic, assign) int64_t sentTime;
@property(nonatomic, assign) int unreadCount;
@property(nonatomic, assign) BOOL isTop;
@property(nonatomic, strong) ConversationLastMessage *lastMessage;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, assign) int notify;
@property(nonatomic, assign) int atCount;
@end

@interface MessageContent : NSObject
@property(nonatomic, strong) SendUser *sendUser;
@property(nonatomic, assign) ConversationType conversationType;
@property(nonatomic, assign) MessageType messageType;
@property(nonatomic, assign) DirectionType direction;
@property(nonatomic, assign) MessageStatus sentStatus;
@property(nonatomic, assign) uint32_t duration;
@property(nonatomic, assign) uint32_t senderId;
@property(nonatomic, assign) uint32_t targetId;
@property(nonatomic, assign) int64_t messageId;
@property(nonatomic, assign) int64_t serviceMessageId;
@property(nonatomic, assign) int64_t sentTime;
@property(nonatomic, assign) int64_t receivedTime;
@property(nonatomic, copy) NSString *messageUid;
@property(nonatomic, copy) NSString *imageUrl;
@property(nonatomic, copy) NSString *thumb;
@property(nonatomic, copy) NSString *uri;
@property(nonatomic, copy) NSString *voiceUrl;
@property(nonatomic, assign) int64_t voiceDuration;
@property(nonatomic, copy) NSString *content;
@property(nonatomic, copy) NSString *objectName;
@property(nonatomic, copy) NSString *extra;
@property(nonatomic, copy) NSString *inlineExtra;
@end

@interface SendMessageContent : NSObject
@property(nonatomic, assign) ConversationType conversationType;
@property(nonatomic, assign) MessageType messageType;
@property(nonatomic, assign) uint32_t targetId;
@property(nonatomic, copy) NSString *content;
@property(nonatomic, copy) NSString *extra;
@property(nonatomic, strong) SendUser *sendUser;
@end

@interface PushInfo : NSObject
@property(nonatomic, copy) NSString *pushContent;
@property(nonatomic, copy) NSString *pushData;
@property(nonatomic, copy) NSString *pushTitle;

@end