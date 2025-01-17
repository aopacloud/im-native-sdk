#import "MessageCell.h"
#import <CommonCrypto/CommonDigest.h>

@interface MessageCell ()

@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIImageView *messageImageView;
@property (nonatomic, strong) UIButton *voiceButton;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) Message *message;
@property (nonatomic, assign) BOOL isOutgoing;
@property (nonatomic, strong) UILabel *statusLabel;  
@property (nonatomic, strong) UIImageView *recallIcon;  

@end

@implementation MessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {

    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 气泡视图
    self.bubbleView = [[UIView alloc] init];
    self.bubbleView.layer.cornerRadius = 8;
    [self.contentView addSubview:self.bubbleView];
    
    self.recallIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrow.uturn.backward.circle"]];
    self.recallIcon.tintColor = [UIColor grayColor];
    self.recallIcon.hidden = YES;
    [self.bubbleView addSubview:self.recallIcon];

    // 文本标签
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.numberOfLines = 0;
    [self.bubbleView addSubview:self.messageLabel];
    
    // 图片视图
    self.messageImageView = [[UIImageView alloc] init];
    self.messageImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.messageImageView.clipsToBounds = YES;
    self.messageImageView.layer.cornerRadius = 8;
    [self.bubbleView addSubview:self.messageImageView];
    
    // 语音按钮
    self.voiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.voiceButton setImage:[UIImage systemImageNamed:@"waveform.circle.fill"] forState:UIControlStateNormal];
    [self.bubbleView addSubview:self.voiceButton];
    
    // 语音时长标签
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.font = [UIFont systemFontOfSize:12];
    [self.bubbleView addSubview:self.durationLabel];

     // 状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = [UIColor grayColor];
    [self.contentView addSubview:self.statusLabel];
}

- (void)configureWithMessage:(Message *)message isOutgoing:(BOOL)isOutgoing {
    self.message = message;
    self.isOutgoing = isOutgoing;
    
    // 先隐藏所有视图
    self.messageLabel.hidden = YES;
    self.messageImageView.hidden = YES;
    self.voiceButton.hidden = YES;
    self.durationLabel.hidden = YES;
    
    // 根据消息类型配置视图
    if (message.isRecalled) {
        [self configureRecalledMessage];
    } else {
        switch (message.type) {
            case BMSG_TYPE_TEXT:
                [self configureTextMessage];
                break;
            case BMSG_TYPE_IMAGE:
                [self configureImageMessage];
                break;
            case BMSG_TYPE_VOICE:
                [self configureVoiceMessage];
                break;
            default:
                break;
        }
    }
    
    [self setNeedsLayout];

    // 添加状态显示逻辑
    if (isOutgoing) {
        NSString *statusText = @"";
        switch (message.status) {
            case BMSG_STATUS_SENDING:
                statusText = @"发送中...";
                break;
            case BMSG_STATUS_SENT:
                statusText = @"已发送";
                break;
            case BMSG_STATUS_RECEIVED:
                statusText = @"已送达";
                break;
            case BMSG_STATUS_RECEIVED_READ:
                statusText = @"对方已读";
                break;
            case BMSG_STATUS_FAILED:
                statusText = @"发送失败";
                self.statusLabel.textColor = [UIColor redColor];
                break;
            default:
                break;
        }
        self.statusLabel.text = statusText;
        self.statusLabel.hidden = NO;
    } else {
        self.statusLabel.hidden = YES;
    }
}


- (void)configureRecalledMessage {
    self.messageLabel.hidden = NO;
    self.messageLabel.text = @"消息已撤回";
    self.messageLabel.font = [UIFont systemFontOfSize:12]; // 使用小号字体
    self.messageLabel.textColor = [UIColor grayColor];
    self.bubbleView.backgroundColor = [UIColor systemGray6Color];
    self.recallIcon.hidden = NO;
    
    // 确保其他视图隐藏
    self.messageImageView.hidden = YES;
    self.voiceButton.hidden = YES;
    self.durationLabel.hidden = YES;
    
    // 设置较小的圆角
    self.bubbleView.layer.cornerRadius = 12;
}

- (void)configureTextMessage {
    self.messageLabel.hidden = NO;
    NSString *messageText;
    if (self.message.isRecalled) {
        messageText = @"消息已撤回";
    } else {
        messageText = [NSString stringWithFormat:@"%@ (%@)", self.message.content, self.message.userId];
    }
    
    self.messageLabel.text = messageText;
    self.messageLabel.textColor = self.isOutgoing ? [UIColor whiteColor] : [UIColor blackColor];
    self.bubbleView.backgroundColor = self.isOutgoing ? [UIColor systemBlueColor] : [UIColor systemGray5Color];
    
    // 确保其他视图隐藏
    self.messageImageView.hidden = YES;
    self.voiceButton.hidden = YES;
    self.durationLabel.hidden = YES;
}

- (void)configureImageMessage {
    self.messageImageView.hidden = NO;
    self.bubbleView.backgroundColor = [UIColor clearColor];
    
    // 根据消息内容类型处理图片显示
    if ([self.message.content isKindOfClass:[UIImage class]]) {
        // 本地图片直接显示
        self.messageImageView.image = (UIImage *)self.message.content;
    } else if ([self.message.content isKindOfClass:[NSString class]]) {
        NSString *imagePath = (NSString *)self.message.content;
        
        // 检查是否是本地文件路径
        if ([imagePath hasPrefix:@"/"]) {
            // 从本地文件加载图片
            UIImage *localImage = [UIImage imageWithContentsOfFile:imagePath];
            if (localImage) {
                self.messageImageView.image = localImage;
            } else {
                // 加载失败显示占位图
                self.messageImageView.image = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"];
            }
        } else {
            // 显示加载占位图
            self.messageImageView.image = [UIImage systemImageNamed:@"photo.fill"];
            
            // 创建弱引用避免循环引用
            __weak typeof(self) weakSelf = self;
            
            // 在后台线程加载图片
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSURL *url = [NSURL URLWithString:imagePath];
                NSData *imageData = [NSData dataWithContentsOfURL:url];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (imageData) {
                        UIImage *image = [UIImage imageWithData:imageData];
                        if (image) {
                            weakSelf.messageImageView.image = image;
                        } else {
                            weakSelf.messageImageView.image = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"];
                        }
                    } else {
                        weakSelf.messageImageView.image = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"];
                    }
                });
            });
        }
    }
}


#pragma mark - Image Cache

- (void)cacheImage:(UIImage *)image forURL:(NSString *)urlString {
    NSString *filename = [self cacheKeyForURL:urlString];
    NSString *cachePath = [self.class imageCachePath];
    NSString *filePath = [cachePath stringByAppendingPathComponent:filename];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
        [imageData writeToFile:filePath atomically:YES];
    });
}

- (UIImage *)getCachedImageForURL:(NSString *)urlString {
    NSString *filename = [self cacheKeyForURL:urlString];
    NSString *cachePath = [self.class imageCachePath];
    NSString *filePath = [cachePath stringByAppendingPathComponent:filename];
    
    NSData *imageData = [NSData dataWithContentsOfFile:filePath];
    return imageData ? [UIImage imageWithData:imageData] : nil;
}

- (NSString *)cacheKeyForURL:(NSString *)urlString {
    // 使用 URL 的 MD5 作为文件名
    return [[self class] md5:urlString];
}

+ (NSString *)imageCachePath {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    cachePath = [cachePath stringByAppendingPathComponent:@"ImageCache"];
    
    // 创建缓存目录
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                    error:nil];
    }
    
    return cachePath;
}

#pragma mark - MD5

+ (NSString *)md5:(NSString *)string {
    const char *cStr = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    
    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", result[i]];
    }
    
    return md5String;
}

- (void)configureVoiceMessage {
    self.voiceButton.hidden = NO;
    self.durationLabel.hidden = NO;
    
    // 设置语音图标和时长
    UIImage *voiceIcon = [UIImage systemImageNamed:@"waveform.circle.fill"];
    [self.voiceButton setImage:voiceIcon forState:UIControlStateNormal];
    self.durationLabel.text = [NSString stringWithFormat:@"%ld\"", (long)self.message.duration];
    
    // 设置颜色
    self.bubbleView.backgroundColor = self.isOutgoing ? [UIColor systemBlueColor] : [UIColor systemGray5Color];
    self.durationLabel.textColor = self.isOutgoing ? [UIColor whiteColor] : [UIColor blackColor];
    self.voiceButton.tintColor = self.isOutgoing ? [UIColor whiteColor] : [UIColor blackColor];
    
    // 确保其他视图隐藏
    self.messageLabel.hidden = YES;
    self.messageImageView.hidden = YES;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat bubbleMaxWidth = self.contentView.bounds.size.width * 0.7;
    CGFloat bubbleMinWidth = 60;
    CGFloat bubblePadding = 8;
    CGFloat contentMargin = 12; // 左右边距
    
    // 计算气泡大小和位置
    CGSize bubbleSize = CGSizeZero;
    CGFloat bubbleX = 0;
    CGFloat bubbleY = 6; // 默认垂直间距
    
    if (self.message.isRecalled) {
        // 撤回消息使用较小的尺寸
        CGFloat iconSize = 14; // 更小的图标
        CGSize textSize = [@"消息已撤回" boundingRectWithSize:CGSizeMake(bubbleMaxWidth - 2 * bubblePadding - iconSize - 4, CGFLOAT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]}
                                                     context:nil].size;
        
        bubbleSize = CGSizeMake(textSize.width + 2 * bubblePadding + iconSize + 4, 24); // 减小高度
        
        // 根据消息方向设置气泡位置
        bubbleX = self.isOutgoing ? 
            self.contentView.bounds.size.width - bubbleSize.width - contentMargin : contentMargin;
        
         bubbleY = 4; // 撤回消息使用更小的垂直间距
        self.bubbleView.frame = CGRectMake(bubbleX, bubbleY, bubbleSize.width, bubbleSize.height);

        
        // 设置撤回图标位置
        self.recallIcon.frame = CGRectMake(bubblePadding,
                                          (bubbleSize.height - iconSize) / 2,
                                          iconSize,
                                          iconSize);
        
        // 设置文本位置
        self.messageLabel.frame = CGRectMake(CGRectGetMaxX(self.recallIcon.frame) + 4,
                                           (bubbleSize.height - textSize.height) / 2,
                                           textSize.width,
                                           textSize.height);
        
        // 隐藏状态标签
        self.statusLabel.hidden = YES;
        return;
    }
    // 其他消息类型的布局逻辑
    switch (self.message.type) {
        case BMSG_TYPE_TEXT: {
            CGSize textSize = [self.messageLabel.text boundingRectWithSize:CGSizeMake(bubbleMaxWidth - 2 * bubblePadding, CGFLOAT_MAX)
                                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                               attributes:@{NSFontAttributeName: self.messageLabel.font}
                                                                  context:nil].size;
            bubbleSize = CGSizeMake(MAX(textSize.width + 2 * bubblePadding, bubbleMinWidth),
                                    textSize.height + 2 * bubblePadding);
            break;
        }
        case BMSG_TYPE_IMAGE:
            bubbleSize = CGSizeMake(200, 200);
            break;
        case BMSG_TYPE_VOICE:
            bubbleSize = CGSizeMake(120, 40);
            break;
        default:
            break;
    }
    
    bubbleX = self.isOutgoing ? self.contentView.bounds.size.width - bubbleSize.width - 12 : 12;
    self.bubbleView.frame = CGRectMake(bubbleX, bubbleY, bubbleSize.width, bubbleSize.height);
    
    // 根据消息类型设置内容视图的frame
    switch (self.message.type) {
        case BMSG_TYPE_TEXT:
            self.messageLabel.frame = CGRectInset(self.bubbleView.bounds, bubblePadding, bubblePadding);
            break;
            
        case BMSG_TYPE_IMAGE:
            self.messageImageView.frame = self.bubbleView.bounds;
            break;
            
        case BMSG_TYPE_VOICE: {
            CGFloat iconSize = 24;
            if (self.isOutgoing) {
                self.voiceButton.frame = CGRectMake(bubbleSize.width - iconSize - bubblePadding,
                                                  (bubbleSize.height - iconSize) / 2,
                                                  iconSize,
                                                  iconSize);
                self.durationLabel.frame = CGRectMake(bubblePadding,
                                                    (bubbleSize.height - 20) / 2,
                                                    40,
                                                    20);
            } else {
                self.voiceButton.frame = CGRectMake(bubblePadding,
                                                  (bubbleSize.height - iconSize) / 2,
                                                  iconSize,
                                                  iconSize);
                self.durationLabel.frame = CGRectMake(CGRectGetMaxX(self.voiceButton.frame) + bubblePadding,
                                                    (bubbleSize.height - 20) / 2,
                                                    40,
                                                    20);
            }
            break;
        }
    }

     // 设置状态标签的位置
    if (self.isOutgoing) {
        CGFloat statusWidth = 60;
        CGFloat statusHeight = 20;
        self.statusLabel.frame = CGRectMake(
            self.bubbleView.frame.origin.x - statusWidth - 4,  // 气泡左侧4像素间距
            self.bubbleView.frame.origin.y + self.bubbleView.frame.size.height - statusHeight,
            statusWidth,
            statusHeight
        );
    }


     // 设置图片消息的大小
    if (self.message.type == BMSG_TYPE_IMAGE) {
        CGFloat maxWidth = 200;
        CGFloat maxHeight = 200;
        CGFloat minWidth = 100;
        CGFloat minHeight = 100;
        
        CGSize imageSize = self.messageImageView.image.size;
        CGFloat aspectRatio = imageSize.width / imageSize.height;
        CGSize finalSize;
        
        if (aspectRatio > 1) {
            // 宽图
            finalSize.width = MIN(maxWidth, MAX(imageSize.width, minWidth));
            finalSize.height = finalSize.width / aspectRatio;
        } else {
            // 长图
            finalSize.height = MIN(maxHeight, MAX(imageSize.height, minHeight));
            finalSize.width = finalSize.height * aspectRatio;
        }
        
        CGFloat bubbleX = self.isOutgoing ? 
            self.contentView.bounds.size.width - finalSize.width - 12 : 12;
            
        self.bubbleView.frame = CGRectMake(bubbleX, 6, finalSize.width, finalSize.height);
        self.messageImageView.frame = self.bubbleView.bounds;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // 重置所有视图状态
    self.messageLabel.text = nil;
    self.messageImageView.image = nil;
    self.messageLabel.hidden = YES;
    self.messageImageView.hidden = YES;
    self.voiceButton.hidden = YES;
    self.durationLabel.hidden = YES;
    self.recallIcon.hidden = YES; 
    self.bubbleView.backgroundColor = [UIColor clearColor];

     // 重置状态标签
    self.statusLabel.text = nil;
    self.statusLabel.textColor = [UIColor grayColor];
    self.statusLabel.hidden = YES;
}

@end
