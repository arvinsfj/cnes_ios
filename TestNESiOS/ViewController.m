//
//  ViewController.m
//  TestNESiOS
//
//  Created by arvin on 8/25/17.
//  Copyright © 2017 arvin. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "ViewController.h"

#import "AudioQueue.h"

#import "cnes.h"

void wnd_key2btn(int key, char isDown);

@interface ViewController ()
{
    AudioQueue* play;
    short* data_cur;
    short* data_frnt;
    short* data_back;
    unsigned int datalen;
}
@property (weak, nonatomic) IBOutlet UIImageView *canvasImageView;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;

@end

@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    play = [AudioQueue sharePalyer];
    datalen = 0;
    data_frnt = malloc(1024*2*sizeof(short));
    data_back = malloc(1024*2*sizeof(short));
    memset(data_frnt, 0, 1024*2*sizeof(short));
    memset(data_back, 0, 1024*2*sizeof(short));
    data_cur = data_frnt;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(video:) name:@"nes_video" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audio:) name:@"nes_audio" object:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* path = [[NSBundle mainBundle] pathForResource:@"acjmla" ofType:@"nes"];
        cnes_init([path UTF8String]);
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

double time0 = 0; uint8_t fpsArr[100]; uint16_t len = 0;
- (void)calcFPS
{
    double now = CFAbsoluteTimeGetCurrent();
    uint8_t fps = 1/(now - time0);
    time0 = now;
    if (len < 100) {
        fpsArr[len++] = fps;
    }else{
        uint64_t avgFPS = 0;
        for (int i = 0; i < 100; i++) {
            avgFPS+=fpsArr[i];
        }
        avgFPS/=100;
        dispatch_async(dispatch_get_main_queue(), ^{
            _fpsLabel.text = [NSString stringWithFormat:@"%d", (uint8_t)avgFPS];
        });
        len = 0;
        fpsArr[len++] = fps;
    }
}

- (void)video:(NSNotification*)n
{
    //子线程
    [self calcFPS];
    UIImage* image = [n.userInfo objectForKey:@"video"];
    dispatch_async(dispatch_get_main_queue(), ^{
        _canvasImageView.image = nil;
        _canvasImageView.image = image;
    });
}

- (void)audio:(NSNotification*)n
{
    //子线程
    NSNumber* num = [n.userInfo objectForKey:@"audio"];
    short byte = [num shortValue];
    if (datalen < 1024 * 2) {
        data_back[datalen++] = byte;
    } else {
        [play openAudio:data_frnt dataSize:1024*2];
        data_cur = data_back;
        data_back = data_frnt;
        data_frnt = data_cur;
        datalen = 0;
        data_back[datalen++] = byte;
    }
}

- (IBAction)btnDown:(id)sender {
    NSInteger tag = ((UIButton*)sender).tag;
    wnd_key2btn((int)tag, YES);
}
- (IBAction)btnUp:(id)sender {
    NSInteger tag = ((UIButton*)sender).tag;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        wnd_key2btn((int)tag, NO);
    });
}

@end
