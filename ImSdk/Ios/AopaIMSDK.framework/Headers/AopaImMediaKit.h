#import <Foundation/Foundation.h>


@protocol AopaImMediaSink <NSObject>

@required
- (void)OnRecordStatusChanged:(int)status ;
- (void)OnPlayStatusChanged:(int)status ;
@end

__attribute__((visibility("default"))) @interface AopaImMediaKit : NSObject

+ (instancetype)sharedInstance;


- (void)initialize:(NSString *)publicStoragePath;

- (void)setEventHandler:(id<AopaImMediaSink>)eventHandler;

- (void)startRecording:(NSString *)messageId;

- (int)stopRecording;

- (int)startPlaying:(NSString *)messageId;
                    
- (int)stopPlaying;
@end
