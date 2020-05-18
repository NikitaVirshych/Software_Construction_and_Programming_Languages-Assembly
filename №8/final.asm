.model tiny
.code
.org 100h

start:  
    jmp main

;Адреса старых прерываний
oldTimerHandler dd 0
oldKeyboardHandler dd 0  

delay dw 0                          ;Задержка в секундах  
current dw 0                        ;Прошедшее время
ticks db 18
saving db 0                         

;Новое прерывание таймера
timerHandler proc far
    pushf 
    ;Старый обработчик
    call dword ptr cs:oldTimerHandler
    
    pusha
    push ds
    push es
    push cs
    pop ds
    
    cmp saving, 1
    je timerIntEnd 
    
    dec ticks
    jnz timerIntEnd
    
    mov ticks, 18
    
    dec current
    jnz timerIntEnd
    
    mov ax, delay
    mov current, ax
    
    call changeScreen

    timerIntEnd:
    pop es
    pop ds
    popa
    iret
timerHandler endp

;Новое прерывание клавиатуры
keyboardHandler proc far
    pushf  
    ;Старый обработчик
    call dword ptr cs:oldKeyboardHandler
    
    pusha
    push es
    push ds
    push cs
    pop ds 
    
    ;Проверка нажатия Esc
    cli
        mov ah, 11h
        int 16h
        jz keep

        cmp al, 1Bh
        jne keep

        ;Восстановка старых обработчиков
        mov dx, WORD PTR cs:oldTimerHandler
        mov ds, WORD PTR cs:oldTimerHandler + 2
        mov al, 1Ch
        mov ah, 25h
        int 21h 

        mov dx, WORD PTR cs:oldKeyboardHandler
        mov ds, WORD PTR cs:oldKeyboardHandler + 2
        mov al, 09h
        mov ah, 25h
        int 21h 

        push cs
        pop ds

        keep:
    sti
    
    cmp saving, 0
    je keyboardIntEnd
   
    call changeScreen

    keyboardIntEnd: 
    mov ticks, 18 
    mov ax, delay
    mov current, ax  
    
    pop es
    pop ds
    popa
    iret
keyboardHandler endp

;Процедура смены изображения на экране
changeScreen proc
    pusha 
    push cs
    pop ds
    
    cmp saving, 0
    je new
    mov ax, 0500h  
    int 10h
    mov saving, 0 
    jmp changeEnd
    
    new:
    mov ax, 0501h   
    int 10h
    mov saving, 1 
    
    changeEnd:

    popa
    ret            
changeScreen endp
      
main: 
    call getDelay                   ;Получение задержки из командной строки
    
    cmp delay, 0
    je incorrectInput
    
    mov ax, delay
    mov current, ax
     
    cli 
        
        ;Получение старого прерывания таймера
        mov al, 1Ch
        mov ah, 35h
        int 21h 

        mov WORD PTR oldTimerHandler, bx
        mov WORD PTR oldTimerHandler + 2, es
        
        ;Переопредение прерывания таймера
        mov dx, offset timerHandler
        mov al, 1Ch
        mov ah, 25h
        int 21h 
         
        ;Получение старого прерывания клавиатуры
        mov al, 09h
        mov ah, 35h
        int 21h 

        mov WORD PTR oldKeyboardHandler, bx
        mov WORD PTR oldKeyboardHandler + 2, es
        
        ;Переопредение прерывания клавиатуры
        mov dx, offset keyboardHandler
        mov al, 09h
        mov ah, 25h
        int 21h 
    sti  
    
    mov dx, offset turnoff
    call outputString 
   
    ;оставить программу резидентной
    mov ax, 3100h      
    mov dx, (main-start+10Fh)/16
    int 21h           
    
    ;Переполнение
    inputOverflow:
    mov dx, offset overflow
    call outputString
    jmp exit
    
    ;Некорректный ввод числа          
    incorrectInput:
    mov dx, offset error
    call outputString 
    
    exit:
    mov ax, 4ch
    int 21h
       
getDelay proc
    pusha
    
    mov si, 82h                     ;Начало командной строки
    xor ax, ax
    
    converse:   
    mov bx, 0Ah
    mul bx                          ;Умножение аккумулятора на 10    
    jo inputOverflow                ;Проверка на переполнение
    
    mov bl, [si]                    ;Символ из строки
    sub bx, '0'                     ;Отнимаем от ascii кода символа ascii код нуля
    
    ;Проверка символа на условие 0 <= x <= 9
    cmp bx, 9                       
    jg incorrectInput
    cmp bx, 0
    jl incorrectInput
    
    add ax, bx                      ;Добавление нового разряда к аккумулятору
    jo inputOverflow                ;Проверка на переполнение
    
    inc si                          ;Переход к следующему символу
   
    cmp [si], 0Dh                   ;Признак конца командной строки
    jne converse
    
    mov delay, ax
       
    popa  
    ret
getDelay endp 

;Вывод строки на экран
outputString proc
    mov ah, 09h
    int 21h
    ret
outputString endp

error db "Error. Incorrect input! cmd arg should be [1, 32.767]$" 
turnoff db "Info: press Esc to turn screensaver off$" 
overflow db "Error. Input overflow! cmd arg should be [1, 32.767]$"

end start
