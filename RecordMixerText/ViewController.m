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


@interface ViewController () {
   
    TFMediaData *_selectedMusic;
    TFAudioFileReader *_fileReader;
    
    AUGraphMixer * _AUGraphMixer;
    
     TFAudioUnitPlayer *_audioPlayer;
    
}


@property (nonatomic, copy) NSString *recordHome;

@property (copy) NSString* curRecordPath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *mp3Path = [[NSBundle mainBundle] pathForResource:@"123" ofType:@"mp3"];
    _selectedMusic = [TFMediaDataAnalyzer mediaDataForItemAt:mp3Path];

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
    
}

- (IBAction)playAudio:(id)sender {
    if (!_audioPlayer) {
        _audioPlayer = [[TFAudioUnitPlayer alloc] init];
    }
    
    NSLog(@"play mixed");
    [_audioPlayer playLocalFile:[_AUGraphMixer.outputPath stringByAppendingString:@".caf"]];
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
