'!org=32768

#define NEX 
#include <nextlib.bas>
#include <keys.bas>

asm 
    nextreg SPRITE_CONTROL_NR_15, %00000011
end asm 

dim x       as uinteger
dim y       as ubyte

LoadSDBank("myfirstsprite.spr",0,0,0,20)
InitSprites2(64,0,20)

do

    ReadKeys()
    UpdatePlayer()
    WaitRetrace2(192)

loop

sub UpdatePlayer()

    UpdateSprite(x,y,0,0,0,0)

end sub 

sub ReadKeys()

    if MultiKeys(KEYP)
        x = x + 1 
    elseif MultiKeys(KEYO)
        x = x - 1 
    endif 

    if MultiKeys(KEYQ)
        y = y - 1 
    elseif MultiKeys(KEYA)
        y = y + 1 
    endif 

end sub 
