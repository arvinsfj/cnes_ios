//
//  cppu.h
//  TestNes
//
//  Created by arvin on 2017/8/16.
//  Copyright © 2017年 com.fuwo. All rights reserved.
//

#ifndef cppu_h
#define cppu_h

#define    PPU_WIDTH        256
#define    PPU_HEIGHT       240

typedef struct
{
    uint8_t priority;
    uint8_t pal;    /* palette entry */
    uint8_t c;    /* colour value */
    uint8_t has_sprite;
    
} pixel;

typedef struct
{
    uint8_t regs[8];//8个寄存器
    uint8_t oam[256];//SPR-RAM (Sprite RAM), to store the sprite attributes.
    uint8_t oamaddr;//0-256
    
    uint8_t ppudata;//ppudata临时缓存变量
    
    uint16_t reg_v;    /* Current VRAM address (15 bits) */
    uint16_t reg_tv;    /* Temporary VRAM address (15 bits) */
    uint8_t  reg_x;    /* Fine X scroll (3 bits) */
    uint8_t  reg_w;    /* First or second write toggle (1 bit) */
    
    uint32_t attr;      /* Attribute buffer */
    uint16_t tile_l;    /* Tile bitmap low */
    uint16_t tile_h;    /* Tile bitmap high */
    
    pixel pixels[PPU_HEIGHT][PPU_WIDTH];
    uint8_t pallete_index[PPU_HEIGHT][PPU_WIDTH];
    
    unsigned int frame;
    unsigned int frame_ticks;
    
    int sprite0_hit;
    
    unsigned int scanline_sprites[8];//每条扫描线最多渲染8个精灵
    unsigned int scanline_num_sprites;//当前需要渲染的精灵数目，最大为8
    
    cpu_context *cpu;
    void (*draw)(uint8_t *);
    uint8_t (*read8)(uint16_t);
    void (*write8)(uint16_t, uint8_t);
    
} ppu_context;

void    ppu_init(ppu_context *);
int     ppu_step(ppu_context *);
uint8_t ppu_read(ppu_context *, uint16_t);
void    ppu_write(ppu_context *, uint16_t, uint8_t);

#endif /* cppu_h */
