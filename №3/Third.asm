.model small

.stack 100h

.code

greeting proc
    
    mov dx, offset greeting1
    call outputString
    
    mov ax, maxSize
    call outputNum
    
    mov dx, offset greeting2
    call outputString
    
    ret
greeting endp

clearOutput proc
    
    mov di, offset output
    mov cx, 8
    
    clearOutputLoop:
    
    mov [di], '$'
    
    inc di
    loop clearOutputLoop
    
    ret
clearOutput endp

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

;Перевод введенной строки в число
strToNum MACRO str
    xor cx, cx
    xor ax, ax                      ;Обнуление ах
    mov si, offset str[2]           ;Начала строки для перевода
    mov cl, [str+1]                 ;Кол-во введенных символов
    
    cmp cx, 0                       ;Проверка на ввод пустой строки
    je emptyInput
     
    ;Проверка на ввод + в начале числа для пропуска
    cmp [si], '+'
    jne minus
    sub cx, 1 
    inc si
    jmp converse
    
    ;Проверка на ввод - в начале числа для пропуска
    minus:
    cmp [si], '-'
    jne converse
    sub cx, 1 
    inc si
    
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
    loop converse 
    
    cmp ax, 0                       ;Проверка соответствия знака (переполнение)
    jl inputOverflow
    
    ;Проверка на - в начале строки
    cmp [str+2], '-'
    jne strToNumEnd 
    neg ax                          ; *(-1)
                  
    strToNumEnd:               
ENDM

;Ввод массива чисел
getArray proc 
    mov di, offset array    
    mov cx, maxSize    
    jmp arrayInputLoop
    
    ;Введена пустая строка
    emptyInput:
    pop cx
    mov dx, offset empty
    call outputString
    jmp arrayInputLoop
    
    ;Переполнение
    inputOverflow:
    pop cx                          ;Получение значения счетчика из стека
    mov dx, offset overflow
    call outputString
    jmp arrayInputLoop
    
    ;Некорректный ввод числа          
    incorrectInput:
    pop cx                          ;Получение значения счетчика из стека
    mov dx, offset error
    call outputString          
              
    arrayInputLoop:
    ;Вывод строки - просьбы ввода
    mov dx, offset enterNum
    call outputString
    
    ;Ввод числа
    mov dx, offset input 
    call inputString           
    
    push cx                         ;Занесение значения счетчика в стек
    strToNum input                  ;Перевод строки в число  
    pop cx                          ;Получение значения счетчика из стека
    
    mov [di], ax                    ;Занесение числа в массив
    add di, 2                    
    
    loop arrayInputLoop
    ret             
getArray endp

outputArray proc
    
    mov cx, maxSize                 ;Размер массива
    mov si, offset array
    
    mov dx, offset your
    call outputString
    
    outputArrayLoop:
    
    push cx                         ;Сохранение счетчика
    mov ax, [si]                    ;Элемент массива
    call outputNum                  ;Вывод элемента
    pop cx
    
    cmp cx, 1
    je finishOutput
    ;Вывод разделителя
    mov dx, offset separator
    call outputString
         
    add si, 2                       ;Следующий элемент
    loop outputArrayLoop
    
    finishOutput:
    ret
outputArray endp

setRepArray proc
    
    mov cx, maxSize                 ;Размер массива
    mov si, offset array
    
    arrayLoop:
    mov ax, [si]                    ;Элемент массива
    push si                         ;Сохранение текущего места в массиве в стек
    push cx                         ;Сохранение счетчика в стек
    
    mov cx, maxSize                 ;Размер массива
    mov si, offset array
    searchLoop:
    
    cmp [si], ax                    ;Сравнение выбранного элемента с элементом массива
    je found
    
    add si, 2                       ;Следующий элемент массива
    loop searchLoop
    
    found:
    sub si, offset array            ;Получение сдвига в исходном массиве
    add si, offset repArray         ;Получение соответствующего элемента в ассоциативном массиве
    inc [si]                        ;Увеличение кол-ва повторений
    
    pop cx                          ;Получение счетчика из стека
    pop si                          ;Получение текущего места в массиве из стека
    add si, 2                       ;Следующий элемент массива     
    loop arrayLoop
    
    ret
setRepArray endp

getMaxRep proc
    
    
    mov cx, maxSize                 ;Размер массива
    mov di, offset repArray
    mov ax, [di]                    ;Сохранение первого элемента
    
    mov si, offset repArray
    add si, 2
    
    repSearchLoop:
    
    cmp [si], ax                    ;Сравнение выбранного элемента с элементом массива
    jle skip
    
    ;Сохранение нового наибольшего значения
    mov di, si
    mov ax, [di]
    
    skip:
    add si, 2                       ;Следующий элемент 
    loop repSearchLoop
    
    sub di, offset repArray         ;Получение сдвига в ассоциативном массиве
    add di, offset array            ;Получение соответствующего элемента в исходном массиве
    
    mov ax, [di]                    ;Сохранение наиболее часто встречающегося элемента
      
    ret
getMaxRep endp
              
outputNum proc
    
    call clearOutput
    
    xor cx, cx                      ;Обнуление счетчика
    mov bx, 0Ah                     ;10
    mov di, offset output           ;Строка для вывода числа
    
    ;Сравнение выводимого числа с 0
    cmp ax, 0
    jge pos
    
    ;Занесение минуса в строку и получение модуля числа
    mov [di], '-'
    inc di
    neg ax
    
    ;Вывод нуля, если число = 0
    pos:
    cmp ax, 0
    jne toStack
    mov [di], '0'
    jmp printNum
    
    
    toStack:
    ;Проверка на необходимость перевода
    cmp ax, 0
    je toStr
    
    xor dx, dx                      ;Обнуление dx
    div bx                          ; ax/10 - остаток в dl
    add dl, '0'                     ;Получение ascii кода цифры в dl
    push dx                         ;Занесение символа в стек
    inc cx                          ;Увеличение счетчика символов
    
    jmp toStack
    
    toStr:
    pop dx                          ;Получение символа из стека
    mov [di], dx                    ;Занесение символа строку
    inc di
    loop toStr
    
    ;Вывод результата
    printNum:
    mov dx, offset output
    call outputString 
    
    ret              
outputNum endp   
              
start:
mov ax, @data
mov ds, ax
mov es, ax 

mov [input], maxLen

call greeting

call getArray                   ;Ввод массива

mov ax, 03
int 10h

call outputArray                ;Вывод исходного масива на экран

mov dx, offset result
call outputString

call setRepArray                ;Получение массива повторений

call getMaxRep                  ;Нахождение наиболее часто встречающегося числа

call outputNum                  ;Вывод наиболее часто встречающегося числа

;Завершение выполнения программы
Exit:
mov ax, 4ch
int 21h 

.data 
;Информационные строки  
greeting1 db "Input $"
greeting2 db "numbers from -32.767 to 32.767",0Ah,'$'
your db 0Dh,0Ah,0Ah,"Your array: $" 
separator db ", $"
result db 0Dh,0Ah,0Ah,"Most frequent number: $"
enterNum db 0Dh,0Ah,"Enter number: $"        
error db 0Dh,0Ah,"Error. Incorrect input!$" 
overflow db 0Dh,0Ah,"Error. Input overflow$!"
empty db 0Dh,0Ah,"Error. Empty input!$"

input db 09h dup('$')           ;Строка для ввода числа    
output db 08h dup('$')          ;Строка для вывода числа    
maxLen equ 07h

maxSize equ 6                   ;Размер массива
array dw maxSize dup (?)        ;Исходный массив 
repArray dw maxSize dup (0)     ;Массив повторений

end start