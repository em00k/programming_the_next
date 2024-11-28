'!org=32768
'!arch=48k

#define NEX 
#define IM2

#include <nextlib.bas>
#include <keys.bas>

asm 
    di 
    nextreg SPRITE_CONTROL_NR_15, %00010011
    nextreg GLOBAL_TRANSPARENCY_NR_14, 0 
end asm 

dim x       as uinteger
dim y       as ubyte
dim ph      as ubyte 
dim pd      as ubyte 
dim ph_counter  as ubyte 
dim pv_counter  as ubyte 

Declare function CheckBlock(x as ubyte, y as ubyte, level as ubyte) as ubyte 

LoadSDBank("tiles.spr",0,0,0,32)
LoadSDBank("myfirstsprite.spr",0,0,0,20)
InitSprites2(64,0,20)
SetUpLevel(0)

' for ty = 0 to 11
'     for tx = 0 to 15
'         print at ty*2,tx*2;CheckBlock(tx,ty,0)
'     next tx 
' next ty     


do

    ReadKeys()
    UpdatePlayer()
    WaitRetrace2(192)
    
loop

sub UpdatePlayer()

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

    if ph_counter = 0 
        if MultiKeys(KEYP)
            if CheckBlock((x>>4)+1,y>>4,0) = 0 
                pd = 1      ' right 
                ph_counter = 16 
            endif 
        elseif MultiKeys(KEYO)
            if CheckBlock((x>>4)-1,y>>4,0) = 0 
                pd = 2      ' left 
                ph_counter = 16
            endif 
        endif 
        if MultiKeys(KEYQ)
            if CheckBlock((x>>4),(y>>4)-1,0) = 0 
                pd = 3      ' up  
                ph_counter = 16 
            endif 
        elseif MultiKeys(KEYA)
            if CheckBlock((x>>4),(y>>4)+1,0) = 0 
                pd = 4      ' down 
                ph_counter = 16
            endif 
        endif 
    endif 

end sub 


function CheckBlock(x as ubyte, y as ubyte, level as ubyte) as ubyte 

    dim offset      as uinteger
    dim block       as ubyte 
    dim count       as uinteger

    offset = cast(uinteger, level)*(16*12)     ' 16x12 level size
    count = ((y * 16) + cast(ubyte,x) )

    block = peek (@level_data + offset + count )

    return block 

end function


sub SetUpLevel(level as ubyte)

    dim offset      as uinteger
    dim block       as ubyte 
    dim count       as ubyte 

    offset = cast(uinteger, level)*(16*12)          ' 16x12 level size

    for yy = 0 to 11
        for xx = 0 to 15 
            block = peek (@level_data + offset + cast(uinteger, count))
            DoTileBank16(xx,yy,block,32)
            count = count + 1
        next xx 
    next yy 

end sub 


level_data:
asm 
    db 0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
    db 1,0,0,0,0,1,1,1,1,1,1,0,2,0,0,1
    db 1,0,1,1,0,1,0,0,0,1,1,0,2,0,0,1
    db 1,0,1,1,0,1,0,0,0,1,1,0,2,0,0,1
    db 1,0,1,1,0,1,0,0,0,0,0,0,2,0,0,1
    db 1,0,1,1,0,1,1,1,1,1,1,0,2,0,0,1
    db 1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,1
    db 1,0,1,1,1,1,1,0,1,1,1,1,1,1,0,1
    db 1,0,1,1,1,1,1,0,1,1,1,1,1,1,0,1
    db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
end asm 