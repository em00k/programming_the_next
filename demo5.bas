'!org=32768
'!opt=2

#define NEX 
#define IM2

#include <nextlib.bas>
#include <keys.bas>

asm 
    di 
    nextreg SPRITE_CONTROL_NR_15, %00010011
    nextreg GLOBAL_TRANSPARENCY_NR_14, 0 
end asm 

const MLEFT         as ubyte = 0 
const MRIGHT        as ubyte = 1 
const MUP	        as ubyte = 2 
const MDOWN	        as ubyte = 3 
const MSTILL	    as ubyte = 4
const BLOCKSTART	as ubyte = 19
const JUMPMAX	    as ubyte = 32
const TILEWALL      as ubyte = 0
const spleft        as ubyte = %1000					' thare constants required for sprite mirror + flipping 
const spright       as ubyte = %0000
const spup          as ubyte = %0000
const spdown        as ubyte = %0100

dim x               as uinteger
dim y               as ubyte
dim ph              as ubyte 
dim pd              as ubyte 
dim ph_counter      as ubyte 
dim pv_counter      as ubyte 
dim spritecount     as ubyte = 0 
dim bmove           as ubyte = 1 
dim bdir            as ubyte 
dim frametime       as ubyte = 0 
dim anim_time       as ubyte = 0 


Declare function CheckBlock(x as ubyte, y as ubyte, level as ubyte) as ubyte 
Declare function CanGo(direction as ubyte, tx as uinteger, ty as ubyte) as ubyte 

' load the tiles 
LoadSDBank("tiles.spr",0,0,0,32)

' load the sprites 
LoadSDBank("myfirstsprite.spr",0,0,0,20)

' init the sprites 
InitSprites2(64,0,20)

' set up the level 
SetUpLevel(0)

do
    ReadKeys()          ' read the keys             
    UpdatePlayer()      ' update the player        
    UpdateBaddies()     ' update the baddies 
    UpdateFrameTime()   ' update the frame time 
    WaitRetrace2(192)   ' wait for retrace 
loop

' end of program 

sub UpdateFrameTime()
    ' this updates the frame time 
    if frametime > 0 
        frametime = frametime - 1
    else
        frametime = 20              ' reset to 20
        anim_time = 1 - anim_time   ' toggle between 0 and 1
    endif 
end sub 

sub UpdatePlayer()
    ' this updates the player 
    if ph_counter > 0 
        if pd = 1 
            if x < 240
                x = x + 1 
            endif 
        elseif pd = 2 
            if x > 0 
                x = x - 1
            endif  
        elseif pd = 3
            if y > 0 
                y = y - 1
            endif  
        elseif pd = 4
            if y < 11*16
                y = y + 1
            endif  
        endif           
        ph_counter = ph_counter - 1
    else 
        pd = 0 
    endif 

    UpdateSprite(32+x,32+y,0,0,0,0)

end sub 

sub ReadKeys()
    ' this reads the keys 
    dim tx, ty as ubyte 
    tx = x>>4 : ty = y>>4

    if ph_counter = 0 
        if MultiKeys(KEYP)
            if CheckBlock(tx+1,ty,0) = 0 
                pd = 1      ' right 
                ph_counter = 16 
            endif 
        elseif MultiKeys(KEYO)
            if CheckBlock(tx-1,ty,0) = 0 
                pd = 2      ' left 
                ph_counter = 16
            endif 
        endif 
        if MultiKeys(KEYQ)
            if CheckBlock(tx,(ty-1),0) = 0 
                pd = 3      ' up  
                ph_counter = 16 
            endif 
        elseif MultiKeys(KEYA)
            if CheckBlock(tx,(ty+1),0) = 0 
                pd = 4      ' down 
                ph_counter = 16
            endif 
        endif 
    endif 

end sub 

function CheckBlock(x as ubyte, y as ubyte, level as ubyte) as ubyte 
    ' this checks the block
    dim offset      as uinteger
    dim block       as ubyte 
    dim count       as uinteger

    offset = cast(uinteger, level)*(16*12)     ' 16x12 level size
    count = ((y * 16) + cast(ubyte,x) )

    block = peek (@level_data + offset + count )

    if block = 2     ' 2 is a baddie spawn point   
        return 0
    else
        return block 
    endif 

end function


sub AddBaddies(sp_id as ubyte, bx as uinteger, by as ubyte)
    ' this adds the baddie to the sprite table 
    '  [x],y,frame,direction, 
    dim offset      as uinteger
    dim spraddress  as uinteger

    if spritecount > 16         ' max 16 baddies 
        return 
    endif 

    offset = spritecount * 16 
    spraddress = @spritetable+cast(uinteger,offset)

    poke Uinteger spraddress,bx 
    poke spraddress+2,by        ' y 
    poke spraddress+3,0         ' frame 
    poke spraddress+4,bdir      ' direction 
    
    spritecount = spritecount + 1 ' increment 

end sub


sub UpdateBaddies()
    ' this updates the baddie 
    dim spraddress as uinteger
    dim tx as uinteger
    dim ty, ti, td as ubyte 
    dim offset as uinteger
    dim flip as ubyte 
     
    for sp = 0 to spritecount-1
        offset = sp << 4                    ' Optimize: use shift instead of multiply
        spraddress = @spritetable + offset
        tx = peek(uinteger,spraddress)
        ty = peek(spraddress+2)
        ti = peek(spraddress+3)
        td = peek(spraddress+4)

        ti = 1 - ti                         ' Toggle frame between 0 and 1
        
        if bmove = 1
            if CanGo(td,tx,ty) > 0         ' Check current direction first
                td = int(rnd*4)             ' Change direction if blocked
            else
                if td = MLEFT
                    tx = tx - 1 
                    if tx <= 32: td = MRIGHT: endif
                    flip = 0 
                elseif td = MRIGHT
                    tx = tx + 1
                    if tx = 0: td = MLEFT: tx = 254: endif
                    flip = 8 
                elseif td = MUP
                    ty = ty - 1
                    if ty <= 32: td = MDOWN: endif
                elseif td = MDOWN
                    ty = ty + 1
                    if ty >= 208: td = MUP: endif
                endif 
            endif 
        endif

        ' Store updated values
        poke uinteger spraddress,tx 
        poke spraddress+2,ty
        poke spraddress+3,ti
        poke spraddress+4,td
        
        UpdateSprite(tx,ty,1+sp,2+anim_time,flip,0)
    next 

end sub 

function CanGo(direction as ubyte, tx as uinteger, ty as ubyte) as ubyte 
    ' this checks if the baddie can go in the direction 
    dim tilex as ubyte = cast(ubyte,(tx-32+8)>>4)      ' Default to center X
    dim tiley as ubyte = cast(ubyte,(ty-32+8)>>4)      ' Default to center Y
    
    if direction = MLEFT 
        tilex = (tx-32)>>4                 ' Only adjust X for left
    elseif direction = MRIGHT
        tilex = (tx-32+15)>>4              ' Only adjust X for right
    elseif direction = MUP
        tiley = (ty-32)>>4                 ' Only adjust Y for up
    elseif direction = MDOWN
        tiley = (ty-32+15)>>4              ' Only adjust Y for down
    endif 
    return CheckBlock(tilex,tiley,0)
end function

sub SetUpLevel(level as ubyte)
    ' this sets up the level 
    dim offset      as uinteger
    dim block       as ubyte 
    dim count       as ubyte 

    offset = cast(uinteger, level)*(16*12)          ' 16x12 level size
    ' loop through the level data 
    for yy = 0 to 11
        for xx = 0 to 15 
            block = peek (@level_data + offset + cast(uinteger, count))
            DoTileBank16(xx,yy,block,32)             ' draw the tile    
            count = count + 1
            if block = 2                             ' 2 is a baddie spawn point    
                ' add the baddie to the sprite table 
                AddBaddies(spritecount,32+(xx<<4),32+(yy<<4))       
            endif    
        next xx 
    next yy 
end sub 


level_data:
asm 
    db 0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1
    db 1,0,0,0,0,1,1,1,1,1,1,0,2,0,0,1
    db 1,0,1,1,0,1,0,0,0,1,1,0,2,0,0,1
    db 1,0,1,1,0,1,0,0,0,1,1,0,2,0,0,1
    db 1,0,1,1,0,1,0,0,0,0,0,0,2,0,1,1
    db 1,0,1,1,0,1,1,1,1,1,1,0,2,0,0,1
    db 1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1
    db 1,0,1,0,1,1,1,0,1,1,1,1,1,0,0,1
    db 1,0,0,0,1,1,1,0,1,1,1,1,1,0,0,1
    db 1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
end asm 

spritetable:
asm
spritetable: 
    ;  [x],y,frame,direction,
    defs 6*16,0
end asm
