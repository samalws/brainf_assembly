section .text
 global _start

_start:
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
call findMatchingBrace
jmp .done

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
; TODO actually take user input
mov rdx, [userInputLoc]
mov al, [rdx]
inc rdx
mov [userInputLoc], rdx
mov [rbx], al
jmp .done

.zero:
mov rcx, zeroMsg
mov rdx, zeroMsgLen
call print
jmp exit

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
mov rbx, 1
mov rax, 4
int 0x80
ret

exit:
mov rax, 1
int 0x80

section .data

code:
db "(hello world program) ++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>. (read all the user input) [.,]", 0

dataBegin:
times 30000 db 0
dataEnd:

userInput db "this is the user input", 0xA, 0
userInputLoc dq userInput

singleCharPrintMsg db 0

zeroMsg db "done"
zeroMsgLen equ $ - zeroMsg
