.model small
.stack 100h

.code
jmp main

;Вывод счета  
printScore proc
    pusha
    xor cx, cx    
    mov ax, score
    xor dx, dx 
    mov si, 10
;Запись цифр числа в стек
loadStack:   
    div si 			  		
    add dl, '0'
    push dx    
    xor dx, dx 
    inc cx        
    cmp ax, 0
    jne loadStack   
    mov bx, 466
;Запись цифр из стека в видеопамять    
printStack:
    pop dx 
    push ds
    mov ax, 0b800h
    mov ds, ax
    mov [bx], dl
    inc bx
    mov [bx], 07h
    inc bx
    pop ds           
    loop printStack          
    popa 
    ret   
endp    

;Очистка экрана и вывод рамок 
setScreen proc
    push cx
    push ax
    push si
    push ds  
    push bx
    push dx    
    
    mov ah, 02h
    mov bh, 0
    xor dx, dx
    int 10h
     
    mov ax, 0b800h                  ;Адрес видеопамяти
    mov ds, ax 
    
    ;Очистка экрана
    mov ah, 00 
    mov al, 01                    
    int 10h
    
    xor si, si
    inc si
    ;Верхняя рамка
    mov cx, 40              
    screenTopBorder:
    mov [si], 70h
    add si, 2
    loop screenTopBorder
    
    ;Боковые рамки 
    mov cx, 23
    screenSideBorders:
    mov [si], 70h
    add si, 78
    mov [si], 70h
    add si, 2
    loop screenSideBorders
    
    ;Нижняя рамка
    mov cx, 40
    screenBottomBorder:
    mov [si], 70h
    add si, 2
    loop screenBottomBorder
    
    ;Рамки игрового поля 
    ;Боковые
    mov cx, 2
    gameplaySideBorders:
    mov al, 80
    mul cl
    add ax, 4
    mov si, ax
    inc si
    mov [si], 70h
    add si, 46
    mov [si], 70h
    inc cx
    cmp cx, 23
    je gameplaySideBordersEnd
    jmp gameplaySideBorders
    
    ;Верхняя
    gameplaySideBordersEnd:
    mov cx, 2
    gameplayTopBorder:
    mov al, 2
    mul cl
    add ax, 160
    mov si, ax
    inc si
    mov [si], 70h
    inc cx
    cmp cx, 26
    je gameplayTopBorderEnd
    jmp gameplayTopBorder
    
    ;"Очки"
    gameplayTopBorderEnd:
    mov [454], 'S' 
    mov [456], 'c'
    mov [458], 'o'
    mov [460], 'r'
    mov [462], 'e'
    mov [464], ':'
    mov [615], 20h
    mov [616], '>' 
    mov [619], 30h
    mov [620], '>'
    mov [623], 40h
    mov [624], '>'
    mov [627], 50h
    
    xor bh, bh
    mov dh, 25
    mov ah, 02
    int 10h  
    pop dx
    pop bx
    pop ds
    pop si
    pop ax
    pop cx
    ret
endp

;Перенос уровня в playerField
initPlayField proc
    push cx
    push bx
    push ax  
    push es
    push di
    push si
      
    mov ax, ds
    mov es, ax
    mov si, offset level
    mov di, offset playField  
    mov cx, 396
    rep movsb                       ;Перенос уровня в playField
  
    pop si
    pop di
    pop es 
    pop ax
    pop bx
    pop cx
    ret
endp

;Вывод уровня на экран
displayPlayField proc
    push ax
    push es
    push cx
    push di
    push si 
    
    mov ax, 0B800h                  ;Видеопамять
    mov es, ax
    mov cx, 19                      ;Кол-во рядов
    mov di, 247                     ;Байт атрибута первого символа игрового поля
    mov si, offset playField
    
    rowLoop: 
        push cx
        mov cx, 22                  ;Символов в ряду
        
        colLoop:
        movsb                       ;Копирование si -> di
        inc di                      ;Пропуск бита кода символа
        loop colLoop
        add di, 36                  ;Следующий ряд
        pop cx
        
    loop rowLoop
    
    pop si
    pop di
    pop cx
    pop es
    pop ax
    ret
endp

;Отрисовка платформы
displayPaddle proc       
    push ds
    
    mov bx, offset paddlePosition
    mov dx, [bx]
    
    mov ax, 0b800h
    mov ds, ax
    mov bx, 1767                    ;Начало строки, в которой движется платформа
    mov cx, 22
    ;Очистка строки
    loop21:    
    mov [bx], 00h
    add bx, 2
    loop loop21
       
    mov bx, 1767
    add bx, dx
    add bx, dx
    mov cx, 4 
    ;Вывод платформы
    loop31:    
    mov [bx], 070h
    add bx, 2
    loop loop31
    
    pop ds    
    ret
endp

;Экран приветствия
welcomeScreen proc 
    push ax
    push bx 
    push dx
    
    ;Вывод строки
    mov ah, 9h
    mov dx, offset messageWelcome
    int 21h          
    
    waitEnterWelcome: 
    ;Проверка наличия символов в буфере
    mov ah, 1
    int 16h
    jz waitEnterWelcome
    ;Получение символа из буфера
    xor ah, ah
    int 16h
    cmp ah, 1Ch                         ;Enter
    je EnterWelcome
    cmp ah, 01h                         ;Esc
    jne waitEnterWelcome                    
    ;Завершение при нажатии esc
    jmp exit
    EnterWelcome:
    pop dx
    pop bx
    pop ax      
    ret
endp

;Передвижение шара
moveBall proc
    push dx    
    cmp verticalMovement, 0             ;Напрвление вертикального движения
    jne moveDown                        
    cmp ballPositionY, 0                ;Проверка столкновения с верхней границей
    jne notUpBorder
    mov verticalMovement, 1             ;Изменить вертикальную скорость
    notUpBorder:              
    jmp horizontalCheck                 ;Горизонтальное движение
    moveDown:
    cmp ballPositionY, 18               ;Проверка столкноыения с нижней границей
    jne notDownBorder         
    mov bx, offset paddlePosition
    mov ax, [bx]
    cmp ax, ballPositionX               ;Промах платформы слева
    jg paddleLose
    add ax, 3
    cmp ax, ballPositionX
    jl paddleLose                       ;Промах платформы справа
    mov verticalMovement, 0             ;Изменить вертикальную скорость
    jmp notDownBorder
    ;Выход - поражение
    paddleLose:
    mov ax, 01h
    pop dx
    ret
    notDownBorder: 
    horizontalCheck:
    cmp horizontalMovement, 0           ;Направление горизонтального движения
    jne moveLeft
    cmp ballPositionX, 21               ;Проверка столкновения с правой стенкой
    jne changeBallPos
    mov horizontalMovement, 1           ;Поменять горизонтальную скорость
    jmp changeBallPos
    moveLefT:   
    cmp ballPositionX, 0                ;Проверка столкновения с левой стенкой
    jne changeBallPos   
    mov horizontalMovement, 0           ;Поменять горизонтальную скорость
    changeBallPos: 
    cmp horizontalMovement, 1           ;Направление горизотального движения
    jne moveRight
    dec ballPositionX                   ;Сдвинуть влево
    call checkCollision                 ;Проверить столкновение
    cmp dx, 00h                         ;Результат проверки
    je verticalMove
    inc ballPositionX                   ;Сдвинуть вправо
    mov horizontalMovement, 0           ;Поменять горизонтальную скорость
    jmp verticalMove
    moveRight:
    inc ballPositionX                   ;Сдвинуть вправо
    call checkCollision                 ;Проверить столкновение
    cmp dx, 00h                         ;Результат проверки
    je verticalMove
    dec ballPositionX                   ;Сдвинуть влево
    mov horizontalMovement, 1           ;Поменять горизонтальную скорость
    verticalMove:
    cmp verticalMovement, 1
    jne moveUp
    inc ballPositionY                   ;Сдвинуть вниз
    call checkCollision                 ;Проверить столкновение
    cmp dx, 00h                         ;Результат проверки
    je moveEnd
    dec ballPositionY                   ;Сдвинуть вверх
    mov verticalMovement, 0             ;Поменять верт скорость
    jmp moveEnd
    moveUp:
    dec ballPositionY                   ;Сдвинуть вверх
    call checkCollision                 ;Проверить столкновение
    cmp dx, 00h                         ;Результат проверки
    je moveEnd
    inc ballPositionY                   ;Сдвинуть вниз
    mov verticalMovement, 1             ;Поменять верт скорость
    moveEnd:     
    xor ax, ax
    pop dx
    ret
endp

;Отрисовка шара
displayBall proc           
    push ax
    push bx
    push cx
    push ds     
    mov bx, offset ballPositionY    
    mov ax, [bx]
    add ax, 3                       ;3 ряда сверху
    mov cl, 80                      ;40 символов в ряд по 2 байта на каждый
    mul cl                          
    mov bx, offset BallPositionX
    mov cx, [bx]
    add ax, cx                      
    add ax, cx                      ;x2 байта на каждый символ
    add ax, 6                       ;3 символа по 2 байта
    mov bx, ax
    mov ax, 0b800h                  ;Начало видеопамяти
    mov ds, ax 
    mov [bx], 'o'
    inc bx 
    mov [bx], 07h                   ;Закрашиваем символ
    pop ds
    pop cx
    pop bx
    pop ax
    ret
endp

;Возвращает в dx : 0 - столкновения не произошло, 1 - столкновение произошло
checkCollision proc   
    push ax
    push bx
    push cx    
    xor dx, dx
    mov bx, offset ballPositionY    ;Y координата шара
    mov ax, [bx]
    mov cl, 22                      ;22 символа в одном ряду игрового поля
    mul cl
    mov bx, offset ballPositionX    ;+X координата шара
    mov cx, [bx]
    add ax, cx                      ;Номер клетки в которой находится шар
    mov bx, offset playField
    add bx, ax                      ;Байт атрибута клетки в которой находится шар
    cmp [bx], 00h
    je notCollision                 ;Клетка пустая - столкновения не произошло
    add score, 10                   ;Увеличение счета
    call printScore                 ;Вывод счета 
    mov dx, 01h                     ;Метка столкновения 
    
    ;"Разрушение" клетки или изменение цвета
    cmp [bx], 50h
    jne changeColour   
    mov [bx], 00h   
    dec winCount                    ;Уменьшения счета до победы
    jmp notCollision
    
    ;Изменение цвета клетки
    changeColour:
    add [bx], 10h 
           
    notCollision: 
    pop cx
    pop bx
    pop ax
    ret
endp

;Движение платформы перед стартом
paddleStart proc
    mov bx, offset paddlePosition
    mov ax, [bx]
    add ax, 2
    mov ballPositionX, ax           ;X координата шара - 3 клетка платформы 
    call displayBall                ;Отрисовка шара
    call displayPaddle              ;Отрисовка платформы
    paddleLoop:
    ;Проверка буфера клавиатуры
    mov ah, 1
    int 16h
    jz paddleLoop  
    ;Получение значения из буфера
    xor ah, ah
    int 16h 
    
    cmp ah, 4Dh                     ;Стрелка вправо  
    je paddleRight
    cmp ah, 4Bh                     ;Стрелка влево
    je paddleLeft
    cmp ah, 01h                     ;Esc
    je paddleEsc
    cmp ah, 1Ch                     ;Enter
    je paddleEnter 
    jmp paddleLoop
    
    paddleRight:
    cmp paddlePosition, 18          ;Правая граница
    jge paddleLoop
    inc paddlePosition              ;Сдвинуть платформу вправо
    inc ballPositionX               ;Сдвинуть шар вправо 
    call displayPlayField           ;Отрисовать игровое поле
    call displayPaddle              ;Отрисовать платформу
    call displayBall                ;Отрисовать шар
    jmp paddleLoop
    
    paddleLeft:  
    cmp paddlePosition, 0           ;Левая граница
    je paddleLoop
    dec paddlePosition              ;Сдвинуть платформу влево
    dec ballPositionX               ;Сдвинуть шар влево 
    call displayPlayField           ;Отрисовать игровое поле
    call displayPaddle              ;Отрисовать платформу
    call displayBall                ;Отрисовать шар
    jmp paddleLoop
    
    paddleEsc:
    jmp exit                        ;Выход
    
    paddleEnter:
    ret                             ;Старт игры
endp    

printScreen MACRO Screen   
    pusha 
    
    LOCAL printScrLoop
    LOCAL waitEnterScr 
    LOCAL EnterScr
     
    ;Очистка экрана
    mov ah, 00 
    mov al, 01                    
    int 10h  
    
    mov ax, 0B800h                  ;Видеопамять
    mov es, ax
    mov cx, 880                     
    mov di, 1                       ;Байт атрибута первого символа
    mov si, offset Screen
    
    printScrLoop: 
 
        movsb                       ;Копирование si -> di
        inc di                      ;Пропуск бита кода символа
        
    loop printScrLoop
    
    ;Курсор на предпоследнюю строку
    mov ah, 02h
    mov bh, 0
    mov dh, 23
    mov dl, 0
    int 10h

    ;Вывод сообщения на экран
    mov ah, 9h
    mov dx, offset message
    int 21h
    
    ;Спрятать курсор
    mov ah, 02h
    mov bh, 0
    mov dh, 25
    int 10h         
    
    waitEnterScr:
    ;Проверка буфера клавиатуры
    mov ah, 1
    int 16h
    jz waitEnterScr
    ;Получение значения из буфера
    xor ah, ah
    int 16h 
    
    cmp ah, 1Ch                     ;Enter
    je EnterScr               
    
    cmp ah, 01h                     ;Esc
    jne waitEnterScr
    jmp exit 
    
    EnterScr:
    
    popa      
printScreen ENDM

main:
    mov ax, @data
    mov ds, ax
    mov ah, 00                      ;Установка видеорежима
    mov al, 01                      ;40x25 16-цветный режим с очисткой экрана
    int 10h                 
    call welcomeScreen 
    
    restart:
    ;Стартовые значения величин 
    mov winCount, 30                ;220 клеток всего
    mov score, 0 
    mov previousTime, 0  
    mov ballPositionY, 18
    mov horizontalMovement, 0
    mov verticalMovement, 0 
       
    call setScreen                  ;Очистка экрана и установка границ
    call printScore                 ;Посимвольный вывод счета
    call initPlayField              ;Выбор уровня и установка необходимого кол-ва очков
    call displayPlayField           ;Вывод уровня на экран
    call displayPaddle              ;Вывод платформы на экран
    call paddleStart                ;Выбор стартовой точки 
    
    ;Обнуление счетчика времени
    mov ah, 01h
    xor cx, cx
    xor dx, dx
    int 1ah
         
    start:
    ;Проверка символа в буфере                     
    mov ah, 1
    int 16h
    jz checkTime  
    ;Чтение символа из буфера
    xor ah, ah
    int 16h   
    
    
    cmp ah, 4Dh                     ;Стрелка вправо  
    je Right
    cmp ah, 4Bh                     ;Стрелка влево
    je Left
    cmp ah, 01h                     ;Esc
    je Esc
    jmp checkTime                   ;Ни один из перечисл.
    
    Right:
    cmp paddlePosition, 18          ;Правая граница
    je checkTime
    inc paddlePosition              ;Сдвиг платформы вправо
    call displayPlayField           ;Отрисовка игрового поля
    call displayPaddle              ;Отрисовка платформы
    call displayBall                ;Отрисовка шара
    jmp checkTime
    
    Left:
    cmp paddlePosition, 0           ;Левая граница
    je checkTime             
    dec paddlePosition              ;Сдвиг платформы влево  
    call displayPlayField           ;Отрисовка игрового поля
    call displayPaddle              ;Отрисовка платформы
    call displayBall                ;Отрисовка шара
    jmp checkTime  
    
    Esc:
    jmp exit
     
    checkTime: 
    ;Прочитать счетчик времени
    mov ah, 00h
    int 1ah
    push dx 
    
    mov ax, previousTime            ;Предыдущее значение счетчика
    sub dx, ax            
    mov ax, dx                      ;Прошедшее время
    pop dx
    cmp ax, 3
    jl checkCount                   ;если прошло недостаточно  - не менять кадр
    mov previousTime, dx            ;Сохранение значения счетчика
    call moveBall                   ;Сдвиг мяча
    
    ;Проверка непопадания в платформу
    cmp ax, 01h
    je Lose 
       
    call displayPlayField           ;Отрисовка игрового поля
    call displayPaddle              ;Отрисовка платформы
    call displayBall                ;Отрисовка шара
    
    checkCount:
    cmp winCount, 0
    jg start
    printScreen winScreen
    jmp restart
      
    
    waitEnter:
    ;Проверка буфера клавиатуры
    mov ah, 1
    int 16h
    jz waitEnter 
    ;Чтение из буфера клавиатуры
    xor ah, ah
    int 16h
    cmp ah, 1Ch                     ;Enter
    jne notEnter 
    
    Lose: 
    printScreen loseScreen
    
    jmp restart
    
    notEnter:                       
    cmp ah, 01                      ;Esc
    jne waitEnter
    
exit:
;Переключение видеорежима
mov ah, 00
mov al, 03
int 10h 
;Завершение работы
mov ah, 4Ch
int 21h  

.data
messageWelcome db 0Ah, 0Ah, 0Ah, 0Ah, 0Ah, 0Ah, 0Ah
               db 09h, "   Movement:",0Dh ,0Ah
               db 09h, "   Left/Right arrow",0Dh ,0Ah
               db 09h, "   Esc - exit",0Dh ,0Ah
               db 09h, "   Enter - start",0Dh ,0Ah,'$'
                
message db "     Esc - exit     Enter - restart",'$'

;Длина игрового поля 22 бита, ширина 18
playField db 396 dup(00h)
level db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h 
      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
      db 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h  
      db 50h, 50h, 50h, 50h, 20h, 20h, 20h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h
      db 50h, 50h, 50h, 20h, 50h, 50h, 50h, 20h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h
      db 50h, 50h, 50h, 20h, 50h, 50h, 50h, 20h, 50h, 50h, 30h, 30h, 30h, 50h, 40h, 50h, 50h, 50h, 40h, 50h, 50h, 50h
      db 50h, 50h, 50h, 20h, 20h, 20h, 20h, 20h, 50h, 30h, 50h, 50h, 50h, 50h, 40h, 40h, 50h, 40h, 40h, 50h, 50h, 50h
      db 50h, 50h, 50h, 20h, 50h, 50h, 50h, 20h, 50h, 50h, 30h, 30h, 50h, 50h, 40h, 50h, 40h, 50h, 40h, 50h, 50h, 50h
      db 50h, 50h, 50h, 20h, 50h, 50h, 50h, 20h, 50h, 50h, 50h, 50h, 30h, 50h, 40h, 50h, 50h, 50h, 40h, 50h, 50h, 50h
      db 50h, 50h, 50h, 20h, 50h, 50h, 50h, 20h, 50h, 30h, 30h, 30h, 50h, 50h, 40h, 50h, 50h, 50h, 40h, 50h, 50h, 50h
      db 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h
      db 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h, 50h 
      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h 
      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
    
winScreen db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 20h, 00h, 00h, 00h, 20h, 20h
	      db 00h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 20h, 00h, 00h, 20h, 00h, 00h
	      db 20h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 20h, 00h, 00h, 20h, 00h, 00h
	      db 20h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 20h, 00h, 00h, 20h, 00h, 00h
	      db 20h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 20h, 00h, 00h, 20h, 00h, 00h
	      db 20h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h
	      db 20h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h
	      db 20h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h
	      db 20h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h
	      db 20h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 20h, 20h
	      db 00h, 00h, 00h, 20h, 20h, 20h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h 
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h 
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 20h, 00h
	      db 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 20h
	      db 00h, 00h, 20h, 20h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h  
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 20h
	      db 00h, 00h, 20h, 20h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 20h
	      db 00h, 00h, 20h, 00h, 20h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h 
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 20h
	      db 00h, 00h, 20h, 00h, 20h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 20h
	      db 00h, 00h, 20h, 00h, 00h, 20h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 20h
	      db 00h, 00h, 20h, 00h, 00h, 20h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 20h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 20h
	      db 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	      db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 20h, 00h, 20h, 00h, 00h, 00h, 00h, 20h, 20h, 00h
	      db 00h, 00h, 20h, 00h, 00h, 00h, 20h, 00h, 00h, 20h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
          
          
loseScreen db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
 	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 40h, 00h, 00h, 00h, 40h, 40h
	       db 00h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 40h, 00h, 00h, 40h, 00h, 00h
	       db 40h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 40h, 00h, 00h, 40h, 00h, 00h
	       db 40h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
 	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 40h, 00h, 00h, 40h, 00h, 00h
	       db 40h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 40h, 00h, 00h, 40h, 00h, 00h
	       db 40h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 40h, 00h, 00h
	       db 40h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 40h, 00h, 00h
 	       db 40h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 40h, 00h, 00h
	       db 40h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 40h, 00h, 00h
	       db 40h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 40h
	       db 00h, 00h, 00h, 40h, 40h, 40h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
           db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
           db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 40h, 40h, 00h, 00h, 00h, 40h
           db 40h, 40h, 40h, 00h, 40h, 40h, 40h, 40h, 40h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h 
           db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 40h
           db 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
           db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 40h
           db 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
           db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h
           db 40h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
           db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h
           db 40h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
           db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h
           db 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
           db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h
           db 00h, 00h, 40h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
           db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 40h, 00h, 00h, 00h
           db 00h, 00h, 40h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
           db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 40h, 40h, 40h, 00h, 00h, 00h, 40h, 40h, 00h, 00h, 00h, 40h
           db 40h, 40h, 40h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h         
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	       
verticalMovement dw 0       ;0 - вверх, 1 - вниз
horizontalMovement dw 0     ;0 - право, 1 - лево


; 0;0 - верхний левый угол поля, ограниченного стенками                  
ballPositionY dw 18
ballPositionX dw 11
                   
paddlePosition dw 0                   
previousTime dw 0    
score dw 0                       
winCount dw 0 

end main