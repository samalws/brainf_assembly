section .text
 global _start

_start:
push runCode
jmp readFile ; call with return address = runCode

readFile:
mov ebx, fileName
mov eax, 5 ; open
mov ecx, 0 ; read-only
int 0x80
mov ebx, eax ; file descriptor
mov eax, 3   ; read
mov ecx, code
mov edx, codeLen-1
int 0x80
ret

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
push exitGood ; call with return address = exitGood
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
je exitGood
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
mov rbx, 1
jmp exit

exitGood:
mov rbx, 0

exit:
; rbx: exit code
mov rax, 1
int 0x80

section .data

fileName db "input.txt"

code:
times 10000 db 0
codeLen equ $ - code

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
