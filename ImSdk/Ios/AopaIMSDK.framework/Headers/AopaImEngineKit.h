#import <Foundation/Foundation.h>
#import "AopaImTypes.h"
#import "AopaImModels.h"


// 事件处理协议
@protocol AopaImEventHandler <NSObject>

@required
- (void)onError:(int)code message:(NSString *)msg;
- (void)onConnectStatusChanged:(ConnectStatus)status;
- (void)onKickOutNotify:(int)reason;
- (void)onSendMessage:(int)code message:(NSString *)msg clientMessageId:(int64_t)messageId status:(MessageStatus)status;
- (void)onNewMessageNotify:(MessageContent *)content left:(int)left;
- (void)onReceiveReadReceipt:(ConversationType)type targetId:(uint32_t)targetId timestamp:(int64_t)timestamp;
- (void)onRecallMessageNotify:(MessageContent *)content;
- (void)onCmdMessageNotify:(MessageContent *)content;
- (void)onUnreadCountNotify:(ConversationType)type targetId:(uint32_t)targetId unreadCount:(int)unreadCount;
- (void)onTypingStatusChanged:(ConversationType)type targetId:(uint32_t)targetId;
- (void)onNotification:(NSString *)payload;
- (void)onOnlineMsg:(NSString *)payload;

@end

// 主接口类
__attribute__((visibility("default"))) @interface AopaImEngineKit : NSObject

@property (nonatomic, copy) NSString *storagePath;
@property (nonatomic, copy) NSString *imagesPath;
@property (nonatomic, copy) NSString *voicePath;
@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, copy) NSString *filesPath;
@property (nonatomic, copy) NSString *tempPath;

// 路径管理方法
- (NSString *)getImagePath:(NSString *)fileName;
- (NSString *)getVoicePath:(NSString *)fileName;
- (NSString *)getVideoPath:(NSString *)fileName;
- (NSString *)getFilePath:(NSString *)fileName;
- (NSString *)getTempPath:(NSString *)fileName;
- (void)cleanExpiredFiles:(NSInteger)expireDays;

+ (instancetype)sharedInstance;
+ (void)setRtcServerAddress:(NSString *)address domain:(NSString *)domain;

- (void)initialize:(int)appId 
      packageName:(NSString *)packageName 
      pushVendor:(NSString *)pushVendor
      pushToken:(NSString *)pushToken
      publicStoragePath:(NSString *)publicStoragePath
      chatType:(int)chatType;

- (void)setEventHandler:(id<AopaImEventHandler>)handler;
- (int)login:(uint32_t)uid token:(NSString *)token;
- (void)logout;
- (IMStatus)getStatus;

- (Message *)convertToMessage:(MessageContent *)content isLocal:(BOOL)isLocal;

// 会话管理
- (NSArray<Conversation *> *)getConversationList;
- (NSArray<Conversation *> *)getConversationListByPage:(int)count startTime:(int64_t)startTime;
- (NSArray<NSNumber *> *)getConversationByType:(ConversationType)type;
- (Conversation *)getConversationByMessageId:(int64_t)messageId;
- (Conversation *)getConversation:(ConversationType)type targetId:(uint32_t)targetId;
- (int)removeConversation:(ConversationType)type targetId:(uint32_t)targetId;
- (int)removeAllConversations;

// 消息管理
- (NSArray<MessageContent *> *)getHistoryMessages:(ConversationType)type 
                                        targetId:(uint32_t)targetId 
                               oldestMessageId:(int64_t)messageId 
                                       count:(int)count 
                                  direction:(DirectionType)direction 
                                fromServer:(BOOL)fromServer;
- (MessageContent *)getMessage:(int64_t)messageId;
- (int64_t)insertMessage:(MessageContent *)content;
- (int64_t)sendMessage:(SendMessageContent *)content pushInfo:(PushInfo *)pushInfo;
- (int64_t)sendVoiceMessage:(SendMessageContent *)content 
                  pushInfo:(PushInfo *)pushInfo 
                 filePath:(NSString *)filePath 
                duration:(int)duration;
- (int64_t)sendImageMessage:(SendMessageContent *)content 
                  pushInfo:(PushInfo *)pushInfo 
                   format:(NSString *)format
                 fileData:(NSData *)fileData;
- (int64_t)sendMentionedMessage:(SendMessageContent *)content 
                      pushInfo:(PushInfo *)pushInfo 
                         type:(MentionType)type 
                        uids:(NSArray<NSNumber *> *)uids;
- (int64_t)resendMessage:(int64_t)messageId;
- (int)deleteMessages:(NSArray<NSNumber *> *)messageIds;
- (int)sendDeleteMessage:(ConversationType)type 
               targetId:(uint32_t)targetId 
             messageIds:(NSArray<NSNumber *> *)messageIds;

// 未读消息管理
- (int)getTotalUnreadCount;
- (int)getUnreadCount:(ConversationType)type targetId:(uint32_t)targetId;
- (int)clearMessagesUnreadStatus:(ConversationType)type targetId:(uint32_t)targetId;
- (int)sendReadReceiptMessage:(ConversationType)type 
                    targetId:(uint32_t)targetId 
                  timestamp:(int64_t)timestamp;

// 其他功能
- (int)sendTypingStatus:(ConversationType)type targetId:(uint32_t)targetId;
- (int)recallMessage:(int64_t)messageId;
- (int)setConversationToTop:(ConversationType)type targetId:(uint32_t)targetId isTop:(BOOL)isTop;
- (int)setConversationNotificationStatus:(ConversationType)type 
                              targetId:(uint32_t)targetId 
                            isNotify:(BOOL)isNotify;
- (BOOL)getConversationNotificationStatus:(ConversationType)type targetId:(uint32_t)targetId;
- (int)setMessageExtra:(int64_t)messageId extra:(NSString *)extra;

@end