.model small

.data
enterStr db "Enter string:",0Dh,0Ah,'$'
result db 0Dh,0Ah,"Result is:",0Dh,0Ah,'$'
empty db 0Dh,0Ah,"Error. Empty string!",0Dh,0Ah,'$'
string db 0CBh dup('$') 
maxSize equ 0C8h

.code

;Заносит в cx длину оставшейся части строки. str - строка, cur - текущее местопол. 
len MACRO str, cur 
    xor cx, cx  
    mov cl, str[1]
    add cx, offset str[2]
    sub cx, cur    
ENDM

;Посимвольный вывод строки
sym_output MACRO str
    mov cl, str+1
    mov si, offset str+2
    mov ah, 02h
    output:
    lodsb
    mov dl, al
    int 21h
    loop output   
ENDM

;Пропуск пробелов в строке str
skipSpaces MACRO str  
    LOCAL skip
    sub str, 1
    skip:
    inc str
    cmp [str], ' ' 
    je skip
ENDM  

;Замена символа old на new в строке str
removeSym MACRO str, old, new
    LOCAL skip
    mov cl, [str+1]
    mov di, offset str[2]
    mov al, new
    remove:
    cmp [di], old
    jne skip
    stosb
    skip:
    inc di
    loop remove 
removeSym ENDM

;Вывод строки на экран
outputString proc
    mov ah, 09h
    int 21h
    ret
outputString endp

;Ввод строки
inputString proc
    mov ah, 0Ah
    int 21h
    ret
inputString endp

;Поиск самого длинного слова: 
;dx - первый символ самого длинного слова
;ax - длина самого длинного слова
findMaxWord proc
    len string, si
    mov di, si
    xor bx, bx
    xor ax, ax  
    
    word:
    inc bx
    
    cmp [di+1], ' '   
    je len_cmp                
    cmp cx, 1
    jbe len_cmp  
    
    inc di
    loop word   
    
    len_cmp:  
    cmp bx, ax       
    ja set
    xor bx, bx
    jmp skip_sp
    
    set:  
    mov dx, di
    inc dx
    sub dx, bx
    mov ax, bx
    xor bx, bx
    
    skip_sp:
    inc di
    sub cx, 1
    cmp cx, 1
    jbe end
    cmp [di], ' '
    jne word
    jmp skip_sp 
    
    end:
    mov di, si
    ret
findMaxWord endp
 
; di - Начало подстроки для реверса
; cx - Длина подстроки для реверса
reverse proc    
    rev_loop:
    mov bl, [di]
    add di, cx
    mov bh, [di]
    mov [di], bl
    sub di, cx 
    mov [di], bh
    inc di
    sub cx, 2  
    cmp cx, 0
    jg rev_loop    
    ret
reverse endp

;Проверка конца строки
isEnd proc 
    len string, si
    cmp cx, 1
    jbe outputResult
    mov di, si
    ret
isEnd endp    

start:
mov ax, @data
mov ds, ax
mov es, ax 

mov dx, offset enterStr
call outputString
 
;Ввод строки
mov [string], maxSize          ; Установка максимального размера строки для int 21h-09h 
mov dx, offset string
call inputString

;Установка di и si на начало строки
mov si, offset string[2]
mov di, si 

;Проверка на ввод пустой строки и строки из пробелов
skipSpaces si 
mov di, si
len string, si
cmp cx, 0
je strIsEmpty

;remove_sym string, '$', 13h

sort:  
call findMaxWord 

add dx, ax
sub dx, 1                   ;dx - последняя буква слова для реверса
mov cx, dx
sub cx, si                  ;cx=dx-si - длина подстроки для реверса
call reverse

mov di, si                           
mov cx, ax                  ;cx - длина самого длинного слова (для реверса) 
sub cx, 1
call reverse  
 
add si, ax                  ;Сдвиг начала рабочей подстроки на длину вставленного слова
skipSpaces si               ;Пропуск пробелов    
call isEnd                  ;Проверка на конец строки
mov di, si
mov cx, dx
sub cx, si                  ;cx=dx-si - длина подстроки для реверса
call reverse                                                        

jmp sort 

;Вывод результата
outputResult:
mov dx, offset result
call outputString
sym_output string
jmp Exit

;Вывод сообщения о вводе пустой строки
strIsEmpty:
mov dx, offset empty
call outputString    
 
;Завершение выполнения программы
Exit:
mov ax, 4ch
int 21h 

end start
