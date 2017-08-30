//
//  cwnd.c
//  TestNes
//
//  Created by arvin on 2017/8/16.
//  Copyright © 2017年 com.fuwo. All rights reserved.
//

#import <UIKit/UIKit.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "hqx.h"

uint32_t   RGBtoYUV[16777216];
uint32_t   YUV1, YUV2;

HQX_API void HQX_CALLCONV hqxInit(void)
{
    /* Initalize RGB to YUV lookup table */
    uint32_t c, r, g, b, y, u, v;
    for (c = 0; c < 16777215; c++) {
        r = (c & 0xFF0000) >> 16;
        g = (c & 0x00FF00) >> 8;
        b = c & 0x0000FF;
        y = (uint32_t)(0.299*r + 0.587*g + 0.114*b);
        u = (uint32_t)(-0.169*r - 0.331*g + 0.5*b) + 128;
        v = (uint32_t)(0.5*r - 0.419*g - 0.081*b) + 128;
        RGBtoYUV[c] = (y << 16) + (u << 8) + v;
    }
}

#define    WIDTH        256
#define    HEIGHT       240
#define    MAG          1   //magnification;

static uint32_t palette_sys[] =
{
    0x666666, 0x002A88, 0x1412A7, 0x3B00A4, 0x5C007E, 0x6E0040, 0x6C0600, 0x561D00,
    0x333500, 0x0B4800, 0x005200, 0x004F08, 0x00404D, 0x000000, 0x000000, 0x000000,
    0xADADAD, 0x155FD9, 0x4240FF, 0x7527FE, 0xA01ACC, 0xB71E7B, 0xB53120, 0x994E00,
    0x6B6D00, 0x388700, 0x0C9300, 0x008F32, 0x007C8D, 0x000000, 0x000000, 0x000000,
    0xFFFEFF, 0x64B0FF, 0x9290FF, 0xC676FF, 0xF36AFF, 0xFE6ECC, 0xFE8170, 0xEA9E22,
    0xBCBE00, 0x88D800, 0x5CE430, 0x45E082, 0x48CDDE, 0x4F4F4F, 0x000000, 0x000000,
    0xFFFEFF, 0xC0DFFF, 0xD3D2FF, 0xE8C8FF, 0xFBC2FF, 0xFEC4EA, 0xFECCC5, 0xF7D8A5,
    0xE4E594, 0xCFEF96, 0xBDF4AB, 0xB3F3CC, 0xB5EBF2, 0xB8B8B8, 0x000000, 0x000000,
};

static uint8_t pic_mem_orgl[WIDTH * HEIGHT * 4];
static uint8_t pic_mem_frnt[WIDTH * HEIGHT * 4 * MAG * MAG];
static uint32_t frame_counter;
static double time_frame0;
static uint8_t* ctrl0;

int wnd_init(const char *filename)
{
    hqxInit();
    
    //不知道为什么需要这样转换，尝试最后的结果是这样子
    for (int i = 0; i < 64; i++) {
        //
        uint32_t bgr = palette_sys[i];
        uint8_t b = (bgr>>16)&0xFF;
        uint8_t g = (bgr>>8)&0xFF;
        uint8_t r = (bgr)&0xFF;
        palette_sys[i] = (r<<16|g<<8|b)<<8|0xFF;//BGRA
    }
    
    frame_counter = 0;
    time_frame0 =  CFAbsoluteTimeGetCurrent();
    
    return 0;
}

void byte2image(uint8_t *bytes, uint64_t width, uint64_t height)
{
    CGColorSpaceRef colorRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctxRef = CGBitmapContextCreate(bytes, width, height, 8, width*4, colorRef, kCGImageAlphaPremultipliedFirst);//RGBA
    CGImageRef imgRef = CGBitmapContextCreateImage(ctxRef);
    UIImage* image = [UIImage imageWithCGImage:imgRef];
    if (image) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"nes_video" object:nil userInfo:@{@"video":image}];
    }
    CGColorSpaceRelease(colorRef);
    CGImageRelease(imgRef);
    CGContextRelease(ctxRef);
}

void wnd_draw(uint8_t* pixels)
{
    uint32_t *fb = (uint32_t*)pic_mem_orgl;
    for (unsigned int y = 0; y < HEIGHT; y++){
        for (unsigned int x = 0; x < WIDTH; x++) {
            *fb++ = palette_sys[*(pixels + WIDTH * y + x)];
        }
    }
    
    if (MAG == 1) {
        memcpy(pic_mem_frnt, pic_mem_orgl, WIDTH*HEIGHT*4);
    }
    if (MAG == 2) {
        hq2x_32((uint32_t*)pic_mem_orgl, (uint32_t*)pic_mem_frnt, WIDTH, HEIGHT);
    }
    if (MAG == 3) {
        hq3x_32((uint32_t*)pic_mem_orgl, (uint32_t*)pic_mem_frnt, WIDTH, HEIGHT);
    }
    if (MAG == 4) {
        hq4x_32((uint32_t*)pic_mem_orgl, (uint32_t*)pic_mem_frnt, WIDTH, HEIGHT);
    }
    
    ++frame_counter;
    double delay = (frame_counter*0.016667+time_frame0) - CFAbsoluteTimeGetCurrent();
    if (delay > 0) {
        [NSThread sleepForTimeInterval:delay];//多余的时间还给系统
    }
    
    byte2image(pic_mem_frnt, WIDTH, HEIGHT);
}

void wnd_play(float com)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"nes_audio" object:nil userInfo:@{@"audio":@((short)(com*32767))}];
}

int wnd_poll(uint8_t* ctrl)
{
    if (ctrl0 == NULL) {
        ctrl0 = ctrl;
    }
    return 0;
}

void wnd_key2btn(int key, char isDown)
{
    uint8_t btn = 0;
    switch (key) {
        case 7:
            btn = 1 << 7;//A
            break;
        case 6:
            btn = 1 << 6;//B
            break;
        case 5:
            btn = 1 << 5;//SELECT
            break;
        case 4:
            btn = 1 << 4;//START
            break;
        case 3:
            btn = 1 << 3;//UP
            break;
        case 2:
            btn = 1 << 2;//DOWN
            break;
        case 1:
            btn = 1 << 1;//LEFT
            break;
        case 0:
            btn = 1 << 0;//RIGHT
            break;
    }
    if (isDown){
        ctrl0[0] |= btn;
        ctrl0[1] |= btn;
    }else if (!isDown){
        ctrl0[0] &= ~btn;
        ctrl0[1] &= ~btn;
    }
}


