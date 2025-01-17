#import "ChatViewController.h"
#import "MessageCell.h"
#import <AVFoundation/AVFoundation.h>
#import "IMTokenManager.h"

@interface ChatViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) NSMutableArray<Message *> *messages;

// 录音相关
@property (nonatomic, strong) UIView *audioRecordingView;
@property (nonatomic, strong) UILabel *audioCountdownText;
@property (nonatomic, strong) NSTimer *recordingTimer;
@property (nonatomic, assign) NSInteger recordingDuration;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, strong) NSString *recordingPath;
@property (nonatomic, assign) NSTimeInterval recordStartTime;

// 输入状态
@property (nonatomic, strong) NSTimer *typingTimer;
@property (nonatomic, assign) BOOL isTyping;

@end

@implementation ChatViewController
static int64_t lastMessageId = 0;
#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
     // 添加键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(keyboardWillShow:) 
                                             name:UIKeyboardWillShowNotification 
                                           object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(keyboardWillHide:) 
                                             name:UIKeyboardWillHideNotification 
                                           object:nil];

    self.messages = [NSMutableArray array];
    [self setupUI];
    //[self setupAudioSession];
    [self setupEventHandler];
    
    self.title = [NSString stringWithFormat:@"与 %@ 的对话", self.remoteUserId];

    [self loadHistoryMessages];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        CGFloat bottomConstraintConstant = keyboardFrame.size.height;
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        //self.bottomConstraint.constant = 0;
        [self.view layoutIfNeeded];
    }];
}


- (void)loadHistoryMessages {
    // 确定目标ID
    int localTargetId = self.chatType == BMSG_PRIVATE_CHAT ? 
                        [self.remoteUserId intValue] : 
                        [self.groupId intValue];
    
    // 获取本地和远程历史消息
    NSArray<MessageContent *> *localMsgs = [[AopaImEngineKit sharedInstance] getHistoryMessages:self.chatType
                                                                                      targetId:localTargetId
                                                                              oldestMessageId:-1
                                                                                       count:100
                                                                                   direction:BMSG_DIRECTION_SEND
                                                                                 fromServer:NO];
    
    NSArray<MessageContent *> *remoteMsgs = [[AopaImEngineKit sharedInstance] getHistoryMessages:self.chatType
                                                                                       targetId:[self.localUserId intValue]
                                                                               oldestMessageId:-1
                                                                                        count:100
                                                                                    direction:BMSG_DIRECTION_SEND
                                                                                  fromServer:NO];
    
    // 合并消息列表
    NSMutableArray<Message *> *allMessages = [NSMutableArray array];
    
    // 处理本地消息
    NSInteger currentIndex = 0;
    NSInteger totalMessages = localMsgs.count;
    
    for (MessageContent *content in localMsgs) {
        currentIndex++;
        Message *message = [[AopaImEngineKit sharedInstance] convertToMessage:content isLocal:YES];
        if (message) {
            [allMessages addObject:message];

            if(content.conversationType == BMSG_GROUP_CHAT){
                        [[AopaImEngineKit sharedInstance] sendReadReceiptMessage:content.conversationType
                                                                           targetId:localTargetId
                                                                           timestamp:content.messageId];
            }
            // 发送已读回执（最后一条消息）
            // if (currentIndex == totalMessages && totalMessages > 0) {
            //     MessageContent *firstMsg = localMsgs.firstObject;
            //     [[AopaImEngineKit sharedInstance] sendReadReceiptMessage:content.conversationType 
            //                                                   targetId:localTargetId 
            //                                                 timestamp:firstMsg.messageId];
            // }
        }
    }
    
    // 处理远程消息
    currentIndex = 0;
    totalMessages = remoteMsgs.count;
    
    for (MessageContent *content in remoteMsgs) {
        currentIndex++;
        Message *message = [[AopaImEngineKit sharedInstance] convertToMessage:content isLocal:NO];
        BOOL isValidSender = NO;
        
        if (self.chatType == BMSG_PRIVATE_CHAT) {
            isValidSender = content.senderId == [self.remoteUserId integerValue];
        } else {
            isValidSender = content.senderId == [self.groupId integerValue];
        }
        
        if (message && isValidSender) {
            [allMessages addObject:message];
            [[AopaImEngineKit sharedInstance] sendReadReceiptMessage:content.conversationType
                                                                          targetId:content.senderId
                                                                        timestamp:content.messageId];
            // 发送已读回执（最后一条消息）
            //if (currentIndex == totalMessages && totalMessages > 0) {
//                MessageContent *firstMsg = remoteMsgs.firstObject;
//                [[AopaImEngineKit sharedInstance] sendReadReceiptMessage:content.conversationType
//                                                              targetId:localTargetId
//                                                            timestamp:firstMsg.messageId];
            //}
        }
    }
    
    // 按时间排序
    @try {
        [allMessages sortUsingComparator:^NSComparisonResult(Message *m1, Message *m2) {
            int64_t time1 = [m1.messageId longLongValue];
            int64_t time2 = [m2.messageId longLongValue];
            if (time1 < time2) {
                return NSOrderedAscending;
            } else if (time1 > time2) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
    } @catch (NSException *exception) {
        NSLog(@"Sort error: %@", exception);
    }
    
    // 更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messages removeAllObjects];
        [self.messages addObjectsFromArray:allMessages];
        [self.messageTableView reloadData];
        [self scrollToBottom];
    });
}

#pragma mark - UI Setup

- (void)setupUI {
    self.messageTableView.delegate = self;
    self.messageTableView.dataSource = self;
    self.messageTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.messageTableView registerClass:[MessageCell class] forCellReuseIdentifier:@"MessageCell"];
    
    self.messageInput.delegate = self;
    [self setupAudioRecordingView];

     // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] 
                                          initWithTarget:self 
                                          action:@selector(handleTapGesture:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
    [self.view endEditing:YES];
}

- (void)setupAudioRecordingView {
    self.audioRecordingView = [[UIView alloc] init];
    self.audioRecordingView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    self.audioRecordingView.layer.cornerRadius = 10;
    self.audioRecordingView.hidden = YES;
    [self.view addSubview:self.audioRecordingView];
    
    self.audioCountdownText = [[UILabel alloc] init];
    self.audioCountdownText.textColor = [UIColor whiteColor];
    self.audioCountdownText.textAlignment = NSTextAlignmentCenter;
    [self.audioRecordingView addSubview:self.audioCountdownText];
    
    self.audioRecordingView.translatesAutoresizingMaskIntoConstraints = NO;
    self.audioCountdownText.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.audioRecordingView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.audioRecordingView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.audioRecordingView.widthAnchor constraintEqualToConstant:200],
        [self.audioRecordingView.heightAnchor constraintEqualToConstant:200],
        
        [self.audioCountdownText.centerXAnchor constraintEqualToAnchor:self.audioRecordingView.centerXAnchor],
        [self.audioCountdownText.centerYAnchor constraintEqualToAnchor:self.audioRecordingView.centerYAnchor]
    ]];
}

- (void)setupAudioSession {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) NSLog(@"Error setting audio session category: %@", error);
    [session setActive:YES error:&error];
    if (error) NSLog(@"Error setting audio session active: %@", error);
}

#pragma mark - Actions

- (IBAction)sendMessage:(id)sender {
    [self sendTextMessage];
}

- (IBAction)selectImage:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)handleAudioRecord:(id)sender {
    self.isRecording ? [self stopAudioRecording] : [self startAudioRecording];
}

- (IBAction)showExitDialog:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"退出聊天" message:@"确定要退出聊天吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
         [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Message Handling

- (void)sendTextMessage {
    NSString *text = self.messageInput.text;
    if (text.length > 0) {
        NSString *messageId = [NSString stringWithFormat:@"%lld", [self generateUniqueMessageId]];
        Message *message = [[Message alloc] initWithType:BMSG_TYPE_TEXT content:text messageId:messageId userId:self.localUserId];
        message.direction = BMSG_DIRECTION_SEND;
        message.status = BMSG_STATUS_SENDING;
        message.userId = self.localUserId;
        [self.messages addObject:message];
        [self.messageTableView reloadData];
        [self scrollToBottom];
        
        self.messageInput.text = @"";
        
        SendMessageContent *content = [[SendMessageContent alloc] init];
        content.conversationType = [self convertChatTypeToConversationType:self.chatType];
        content.messageType = BMSG_TYPE_TEXT;
        content.targetId =  (content.conversationType == BMSG_GROUP_CHAT)?[self.groupId intValue]:[self.remoteUserId intValue];
        content.content = text;
        content.extra = messageId;
        
        PushInfo *pushInfo = [[PushInfo alloc] init];
        pushInfo.pushTitle = @"New message";
        pushInfo.pushData = @"data";
        pushInfo.pushContent = @"type";
        
        [[AopaImEngineKit sharedInstance] sendMessage:content pushInfo:pushInfo];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell" forIndexPath:indexPath];
    Message *message = self.messages[indexPath.row];
    [cell configureWithMessage:message isOutgoing:message.direction == BMSG_DIRECTION_SEND];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = self.messages[indexPath.row];
    CGFloat height = 0;
    CGFloat verticalSpacing = 8;
    
    // 处理撤回消息
    if (message.isRecalled) {
        height = 32; // 撤回消息的固定高度
        return height;
    }
    
    // 处理其他类型消息
    switch (message.type) {
        case BMSG_TYPE_IMAGE:
            height = 200 + verticalSpacing;
            break;
            
        case BMSG_TYPE_TEXT: {
            CGSize textSize = [message.content boundingRectWithSize:CGSizeMake(self.view.bounds.size.width * 0.7 - 24, CGFLOAT_MAX)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16]}
                                                         context:nil].size;
            height = textSize.height + 24 + verticalSpacing;
            break;
        }
            
        case BMSG_TYPE_VOICE:
            height = 40 + verticalSpacing;
            break;
            
        default:
            height = 40 + verticalSpacing;
            break;
    }
    
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self showMessageOptions:self.messages[indexPath.row]];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendTextMessage];
    return YES;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (image) {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.1);
        NSString *messageId = [NSString stringWithFormat:@"%lld", [self generateUniqueMessageId]];
        
        Message *message = [[Message alloc] initWithType:BMSG_TYPE_IMAGE content:image messageId:messageId userId:self.localUserId];
        message.direction = BMSG_DIRECTION_SEND;
        message.status = BMSG_STATUS_SENDING;
        [self.messages addObject:message];
        [self.messageTableView reloadData];
        [self scrollToBottom];
        
        SendMessageContent *content = [[SendMessageContent alloc] init];
        content.conversationType = [self convertChatTypeToConversationType:self.chatType];
        content.messageType = BMSG_TYPE_IMAGE;
        content.targetId = (content.conversationType == BMSG_GROUP_CHAT)?[self.groupId intValue]:[self.remoteUserId intValue];
        content.extra = messageId;
        content.content = @"";
        
        PushInfo *pushInfo = [[PushInfo alloc] init];
        pushInfo.pushTitle = @"New message";
        pushInfo.pushData = @"data";
        pushInfo.pushContent = @"type";
        
        [[AopaImEngineKit sharedInstance] sendImageMessage:content pushInfo:pushInfo format:@"jpg" fileData:imageData];
    }
}

#pragma mark - Audio Recording

- (void)startAudioRecording {
    self.isRecording = YES;
    self.audioButton.selected = YES;
    self.audioRecordingView.hidden = NO;
    self.recordStartTime = [NSDate timeIntervalSinceReferenceDate];
    self.recordingDuration = 0;
    
    self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateRecordingTime) userInfo:nil repeats:YES];
    self.recordingPath = [NSString stringWithFormat:@"%lld", [self generateUniqueMessageId]];
    [[AopaImMediaKit sharedInstance] startRecording:self.recordingPath];
}

- (void)stopAudioRecording {
    [[AopaImMediaKit sharedInstance] stopRecording];
    
    self.isRecording = NO;
    self.audioButton.selected = NO;
    self.audioRecordingView.hidden = YES;
    [self.recordingTimer invalidate];
    
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - self.recordStartTime;
    [self sendVoiceMessage:duration>60?60:duration path:self.recordingPath];

    self.audioCountdownText.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)0, (long)0];
}

- (void)updateRecordingTime {
    self.recordingDuration++;
    if (self.recordingDuration > 60) {
        [self stopAudioRecording];
        return;
    }
    
    NSInteger minutes = self.recordingDuration / 60;
    NSInteger seconds = self.recordingDuration % 60;
    self.audioCountdownText.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

#pragma mark - Voice Message

- (void)sendVoiceMessage:(NSTimeInterval)duration path:(NSString *)path {
    Message *message = [[Message alloc] initWithType:BMSG_TYPE_VOICE content:path messageId:path userId:self.localUserId];
    message.direction = BMSG_DIRECTION_SEND;
    message.status = BMSG_STATUS_SENDING;
    message.duration = (NSInteger)duration;
    [self.messages addObject:message];
    [self.messageTableView reloadData];
    [self scrollToBottom];
    
    SendMessageContent *content = [[SendMessageContent alloc] init];
    content.conversationType = [self convertChatTypeToConversationType:self.chatType];
    content.messageType = BMSG_TYPE_VOICE;
    content.targetId = (content.conversationType == BMSG_GROUP_CHAT)?[self.groupId intValue]:[self.remoteUserId intValue];
    content.content = path;
    content.extra = path;
    
    PushInfo *pushInfo = [[PushInfo alloc] init];
    pushInfo.pushTitle = @"New message";
    pushInfo.pushData = @"data";
    pushInfo.pushContent = @"type";
    
    [[AopaImEngineKit sharedInstance] sendVoiceMessage:content pushInfo:pushInfo filePath:path duration:duration];
}

#pragma mark - Message Operations

- (void)showMessageOptions:(Message *)message {
    if(message.isRecalled){
        return ;
    }

    if(message.direction == BMSG_DIRECTION_SEND || (message.direction == BMSG_DIRECTION_RECEIVE && message.type == BMSG_TYPE_VOICE)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        if(message.direction == BMSG_DIRECTION_SEND){
            [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self handleMessageDelete:message];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"撤回" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self handleMessageRecall:message];
            }]];
        }
        
        if (message.type == BMSG_TYPE_VOICE) {
            [alert addAction:[UIAlertAction actionWithTitle:@"停止播放" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self stopVoiceMessage];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"播放" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self playVoiceMessage:message];
            }]];
        }

        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)stopVoiceMessage {
    if (self.isPlaying) {
        [[AopaImMediaKit sharedInstance] stopPlaying];
        self.isPlaying = NO;
    }
}

- (void)handleMessageDelete:(Message *)message {
    NSInteger index = [self.messages indexOfObject:message];
    if (index != NSNotFound) {
        [self.messages removeObjectAtIndex:index];
        [self.messageTableView reloadData];
    }

    NSNumber *messageId = @([message.messageId longLongValue]);
    uint32_t targetId = (uint32_t)[self.remoteUserId longLongValue];
    [[AopaImEngineKit sharedInstance] sendDeleteMessage:message.type
                                                        targetId:targetId
                                                        messageIds:@[messageId]];
}

- (void)handleMessageRecall:(Message *)message {
    NSInteger index = [self.messages indexOfObject:message];
    if (index != NSNotFound) {
        message.content = @"消息已撤回";
        message.type = BMSG_TYPE_TEXT;
        message.isRecalled = YES;

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.messageTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }

    [[AopaImEngineKit sharedInstance] recallMessage:[message.messageId longLongValue]];
}

- (void)playVoiceMessage:(Message *)message {
    if (message.type == BMSG_TYPE_VOICE) {
        if (self.isPlaying) [self stopVoiceMessage];
        [[AopaImMediaKit sharedInstance] startPlaying:message.messageId];
        self.isPlaying = YES;
    }
}

#pragma mark - Helper Methods

- (int64_t)generateUniqueMessageId {
    int64_t currentTimestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    
    if (currentTimestamp == lastMessageId) {
        lastMessageId++; 
    } else {
        lastMessageId = currentTimestamp; 
    }
    
    return lastMessageId;
}

- (void)scrollToBottom {
    if (self.messages.count > 0) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
        [self.messageTableView scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)showToast:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:nil];
            });
        }];
    });
}

- (ConversationType)convertChatTypeToConversationType:(NSInteger)chatType {
    switch (chatType) {
        case 1: return BMSG_PRIVATE_CHAT;
        case 2: return BMSG_GROUP_CHAT;
        case 3: return BMSG_ROOM_CHAT;
        default: return BMSG_PRIVATE_CHAT;
    }
}

#pragma mark - Event Handler

- (void)setupEventHandler {
    [[AopaImEngineKit sharedInstance] setEventHandler:self];
    [[AopaImMediaKit sharedInstance] setEventHandler:self];
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.typingTimer invalidate];
    [self.recordingTimer invalidate];
    [self stopVoiceMessage];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - AopaImEventHandler

- (void)OnRecordStatusChanged:(int)status {
    [self showToast:[NSString stringWithFormat:@"OnRecordStatusChanged: %d", status]];
}

- (void)OnPlayStatusChanged:(int)status {
    [self showToast:[NSString stringWithFormat:@"OnPlayStatusChanged: %d", status]];
    if (status == 2) [self stopVoiceMessage];
}

- (void)onError:(int)code message:(NSString *)msg {
    [self showToast:[NSString stringWithFormat:@"错误: %d, %@", code, msg]];
}

- (void)onConnectStatusChanged:(ConnectStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (status) {
            case BMSG_STATUS_CONNECTED: [self showToast:@"已连接"]; break;
            case BMSG_STATUS_DISCONNECT: [self showToast:@"连接断开"]; break;
            case BMSG_STATUS_CONNECTING: [self showToast:@"正在连接..."]; break;
            case BMSG_STATUS_LOGGING_IN: [self showToast:@"正在登录..."]; break;
            case BMSG_STATUS_LOGINED: [self showToast:@"已登录..."]; break;
            default: break;
        }
    });
}

- (void)onSendMessage:(int)code message:(NSString *)msg clientMessageId:(int64_t)messageId status:(MessageStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (Message *msg in self.messages) {
            if ([msg.messageId isEqualToString:[NSString stringWithFormat:@"%lld", messageId]]) {
                msg.status = status;
                NSInteger index = [self.messages indexOfObject:msg];
                if (index != NSNotFound) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    [self.messageTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                }
                break;
            }
        }
        
        if (code != 0) [self showToast:[NSString stringWithFormat:@"发送失败: %@", msg]];
    });
}

- (void)onNewMessageNotify:(MessageContent *)content left:(int)left {
    if ((content.senderId != [self.remoteUserId integerValue]) && content.conversationType == BMSG_PRIVATE_CHAT) {
        NSLog(@"Message targetId not match: message targetId=%u, current remoteUserId=%@", 
                content.targetId, self.remoteUserId);
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        Message *message = nil;
        NSString *messageIdStr = [NSString stringWithFormat:@"%lld", content.messageId];
        
        switch (content.messageType) {
            case BMSG_TYPE_IMAGE:
                message = [[Message alloc] initWithType:BMSG_TYPE_IMAGE content:content.imageUrl messageId:messageIdStr userId:self.localUserId];
                break;
            case BMSG_TYPE_VOICE:
                message = [[Message alloc] initWithType:BMSG_TYPE_VOICE content:content.voiceUrl messageId:messageIdStr userId:self.localUserId];
                if (content.duration > 0) message.duration = content.duration;
                break;
            default:
                message = [[Message alloc] initWithType:BMSG_TYPE_TEXT content:content.content messageId:messageIdStr userId:self.localUserId];
                message.userId = [NSString stringWithFormat:@"%d", content.senderId];
                break;
        }
        
        if (message) {
            message.status = content.sentStatus;
            message.direction = content.direction;
            [self.messages addObject:message];
            [self.messageTableView reloadData];
            [self scrollToBottom];
            

            int localTargetId = self.chatType == BMSG_PRIVATE_CHAT ? content.senderId : [self.groupId intValue];
            [[AopaImEngineKit sharedInstance] sendReadReceiptMessage:content.conversationType targetId:localTargetId timestamp:content.messageId];
        }
    });
}

- (void)onReceiveReadReceipt:(ConversationType)type targetId:(uint32_t)targetId timestamp:(int64_t)timestamp {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL needReload = NO;
        for (Message *message in self.messages) {
            if (message.direction == BMSG_DIRECTION_SEND && message.status == BMSG_STATUS_SENT) {
                int64_t messageTimestamp = [message.messageId longLongValue];
                if (messageTimestamp <= timestamp) {
                    message.status = BMSG_STATUS_RECEIVED_READ;
                    needReload = YES;
                }
            }
        }
        if (needReload) [self.messageTableView reloadData];
    });
}

- (void)onRecallMessageNotify:(MessageContent *)content {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (Message *msg in self.messages) {
            if ([msg.messageId longLongValue] == content.messageId) {
                msg.content = @"消息已撤回";
                msg.type = BMSG_TYPE_TEXT;
                msg.isRecalled = YES; 
                if (self.isPlaying) {
                    [[AopaImMediaKit sharedInstance] stopPlaying];
                    self.isPlaying = NO;
                }
                break;
            }
        }
        [self.messageTableView reloadData];
    });
}

- (void)onTypingStatusChanged:(ConversationType)type targetId:(uint32_t)targetId {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.title = @"对方正在输入...";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.title = [NSString stringWithFormat:@"与 %@ 的对话", self.remoteUserId];
        });
    });
}

- (void)onKickOutNotify:(int)reason {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showToast:@"您的账号在其他设备登录"];
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)onCmdMessageNotify:(MessageContent *)content {}
- (void)onUnreadCountNotify:(ConversationType)type targetId:(uint32_t)targetId unreadCount:(int)unreadCount {}
- (void)onNotification:(NSString *)payload {}
- (void)onOnlineMsg:(NSString *)payload {}

@end
