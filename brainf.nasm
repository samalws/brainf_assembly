section .text
 global _start

_start:
call readCharSetMode
; TODO maybe read from a file

runCode:
mov rcx, code
mov rbx, dataBegin
jmp .begin

.done:
inc rcx

.loopAround:
.begin:

mov al, [rcx]
cmp al, '+'
je .plus
cmp al, '-'
je .minus
cmp al, '['
je .openBracket
cmp al, ']'
je .closeBracket
cmp al, '<'
je .leftAngle
cmp al, '>'
je .rightAngle
cmp al, '.'
je .period
cmp al, ','
je .comma
cmp al, 0
je .zero
jmp .done

.plus:
mov al, [rbx]
inc al
mov [rbx], al
jmp .done

.minus:
mov al, [rbx]
dec al
mov [rbx], al
jmp .done

.openBracket:
mov al, [rbx]
cmp al, 0
je .openBracket0
push rcx
jmp .done

.openBracket0:
push .done ; call with return address = .done
jmp findMatchingBrace

.closeBracket:
pop rdx
mov al, [rbx]
cmp al, 0
je .done
mov rcx, rdx
jmp .loopAround

.leftAngle:
dec rbx
cmp rbx, dataBegin
jge .done
mov rbx, dataEnd-1
jmp .done

.rightAngle:
inc rbx
cmp rbx, dataEnd
jl .done
mov rbx, dataBegin
jmp .done

.period:
push rcx
push rbx
mov al, [rbx]
mov [singleCharPrintMsg], al
mov rcx, singleCharPrintMsg
mov rdx, 1
call print
pop rbx
pop rcx
jmp .done

.comma:
push rcx
push rbx
call readChar
pop rbx
pop rcx
mov [rbx], al
jmp .done

.zero:
mov rcx, zeroMsg
mov rdx, zeroMsgLen
push exit ; call with return address = exit
jmp print

findMatchingBrace:
mov rdx, 0
jmp .begin

.loopAround:
inc rcx

.begin:
mov al, [rcx]
cmp al, '['
je .open
cmp al, ']'
je .close
cmp al, 0
je exit
jmp .loopAround

.open:
inc rdx
jmp .loopAround

.close:
dec rdx
cmp rdx, 0
jne .loopAround
ret

print:
; msg stored in rcx
; len stored in rdx
mov rax, 4 ; write
mov rbx, 1 ; stdout file descriptor
int 0x80
ret

readCharSetMode:
mov rax, 54 ; ioctl
mov rbx, 0 ; stdin file descriptor
mov rcx, 0x5401 ; tcgets
mov rdx, termios
int 0x80

mov eax, [termios+0xC] ; lflag
mov [termiosOldLflag], eax
and eax, ~(2 | 8) ; ~(lcanon | echo)
mov [termios+0xC], eax

mov rax, 54 ; ioctl
mov rbx, 0 ; stdin
mov ecx, 0x5402 ; tcsets
mov rdx, termios
int 0x80

readCharResetMode:
mov eax, [termiosOldLflag]
mov [termios+0xC], eax ; lflag

mov rax, 54 ; ioctl
mov rbx, 0 ; stdin
mov ecx, 0x5402 ; tcsets
mov rdx, termios
int 0x80

ret

readChar:
; result stored in al
mov rax, 3 ; read
mov rbx, 0 ; stdin file descriptor
mov rcx, inputByte
mov rdx, 1
int 0x80
cmp rax, 1
jne .err
mov al, [inputByte]
ret

.err:
mov rcx, readCharErrMsg
mov rdx, readCharErrMsgLen

exit:
call readCharResetMode ; TODO what if user ctrl+c 's
mov rax, 1
int 0x80

section .data

code:
db "(hello world program) ++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>. (read all the user input)", 0, " ,[+.,]", 0  ; got rid of user input part because user has to sigint to exit and that causes stdin to not get fixed

dataBegin:
times 30000 db 0
dataEnd:

singleCharPrintMsg db 0

inputByte db 0

zeroMsg db "done"
zeroMsgLen equ $ - zeroMsg

readCharErrMsg db "failed to read char"
readCharErrMsgLen equ $ - zeroMsg

termios: times 32 db 0
termiosOldLflag: dd 0
