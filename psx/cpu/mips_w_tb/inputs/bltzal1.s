.text
addiu $8, $zero, 0xffffffff
addiu $9, $zero, 0x00ff
addiu $11, $zero, 0xff00

bltzal $9, nottaken
nop
bltzal $zero, nottaken
nop
bltzal $8, taken
nop
addiu $2, $0, 10
syscall

taken: 
addiu $2, $0, 10
syscall

nottaken:
addiu $2, $0, 10
syscall
