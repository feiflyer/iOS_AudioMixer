//
//  ViewController.m
//  RecordMixerText
//
//  Created by XingTu on 2019/1/28.
//  Copyright © 2019 IXingTu. All rights reserved.
//

#import "ViewController.h"
#import "TFAudioFileReader.h"
#import "TFAudioFileWriter.h"
#import "AUGraphMixer.h"
#import "TFMediaDataAnalyzer.h"
#import "TFAudioUnitPlayer.h"

#import "AUGraphMixerV2.h"

#define AVPLAYERITEM_STATUS @"status"

@interface ViewController () {
   
    TFMediaData *_selectedMusic;
    TFAudioFileReader *_fileReader;
    
    AUGraphMixer * _AUGraphMixer;
    
     TFAudioUnitPlayer *_audioPlayer;
    
    
    AUGraphMixerV2* aUGraphMixerV2;
    
    AVPlayerItem* avPlayerItem;
    
    AVPlayer* avPlayer;
}


@property (nonatomic, copy) NSString *recordHome;

@property (copy) NSString* curRecordPath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *mp3Path = [[NSBundle mainBundle] pathForResource:@"1234" ofType:@"mp3"];
    _selectedMusic = [TFMediaDataAnalyzer mediaDataForItemAt:mp3Path];
    
    
    aUGraphMixerV2 = [[AUGraphMixerV2 alloc] init];

     [aUGraphMixerV2 initializeAUGraph];
}

- (IBAction)recordAudio:(id)sender {
    
    if ([self mixRuning]) {
        [_AUGraphMixer stop];
//        _AUGraphMixer = nil;
    }else{

        if (!_AUGraphMixer) {
            [self setupGraphMixer];
        }
        _AUGraphMixer.musicFilePath = _selectedMusic.filePath;
        [_AUGraphMixer start];
    }
    
//    if([aUGraphMixerV2 isPlaying]){
//         [aUGraphMixerV2 stopAUGraph];
//    }else{
//         [aUGraphMixerV2 startAUGraph];
//    }

   
    
}

- (IBAction)playAudio:(id)sender {
//    if (!_audioPlayer) {
//        _audioPlayer = [[TFAudioUnitPlayer alloc] init];
//    }
//
//    NSLog(@"play mixed");
//    [_audioPlayer playLocalFile:[_AUGraphMixer.outputPath stringByAppendingString:@".m4a"]];
    
    
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:[_AUGraphMixer.outputPath stringByAppendingString:@".m4a"]]){
        CGFloat size = [[manager attributesOfItemAtPath:[_AUGraphMixer.outputPath stringByAppendingString:@".m4a"] error:nil] fileSize];
        
        NSLog(@"混音文件大小：%f",size);
    }
    
    [self playMusic: [NSURL fileURLWithPath:[_AUGraphMixer.outputPath stringByAppendingString:@".m4a"]]];
    
//    [aUGraphMixerV2 playRecord];
}



- (void) playMusic:(NSURL*) url {
    
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [session setActive:YES error:nil];
    
    avPlayerItem = [[AVPlayerItem alloc] initWithURL:url];
    [avPlayerItem addObserver:self forKeyPath:AVPLAYERITEM_STATUS options:NSKeyValueObservingOptionNew context:nil];
    avPlayer = [[AVPlayer alloc] init];
    [avPlayer replaceCurrentItemWithPlayerItem:avPlayerItem];
    
    NSLog(@"playMusic");
}

// kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == avPlayerItem) {
        if ([keyPath isEqualToString:AVPLAYERITEM_STATUS]) {
            switch (avPlayerItem.status) {
                case AVPlayerItemStatusReadyToPlay:
                    NSLog(@"AVPlayerItemStatusReadyToPlay");
                    //推荐将视频播放放在这里
                    [avPlayer play];
                    
                    
                    
                    break;
                    
                case AVPlayerItemStatusUnknown:
                    NSLog(@"AVPlayerItemStatusUnknown");
                    
                    break;
                    
                case AVPlayerItemStatusFailed:
                    NSLog(@"AVPlayerItemStatusFailed");
                    
                    break;
                    
                default:
                    break;
            }
        }
    }
    
}


-(BOOL)mixRuning{
    return _AUGraphMixer.isRuning;
}

-(void)setupGraphMixer{
    _AUGraphMixer = [[AUGraphMixer alloc] init];
//    for (int i = 0; i<_volumeSliders.count; i++) {
//        [_AUGraphMixer setVolumeAtIndex:i to:_volumeSliders[i].value];
//    }
    _AUGraphMixer.outputPath = [self nextRecordPath];
    [_AUGraphMixer setupAUGraph];
}

-(NSString *)recordHome{
    if (!_recordHome) {
        _recordHome = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"audioMusicMix"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_recordHome]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_recordHome withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    
    return _recordHome;
}

-(NSString *)nextRecordPath{
    NSString *name = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]];
    
    _curRecordPath = [self.recordHome stringByAppendingPathComponent:name];
    
    NSLog(@"curRecordPath:%@",_curRecordPath);
    
    return _curRecordPath;
}

@end
