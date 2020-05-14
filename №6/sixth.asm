;Чтение readLen символов из file
readFile MACRO file  
    mov bx, file 
    mov cx, readLEN
    mov dx, di 
    mov ah, 3Fh
    int 21h    
ENDM             
 
;Закрытие файла
closeFile MACRO file  
    mov bx, file 
    mov ah, 3Eh
    int 21h      
ENDM

;Вывод строки на экран
outputString MACRO string
    push ax
    mov dx, offset string
    mov ah, 09h
    int 21h      
    pop ax
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

;Копирование из si в string до пробела или конца командной строки
copyWord MACRO string
    LOCAL copy
    mov di, offset string
    
    copy:
    movsb
    
    cmp [si], 0Dh           ;Признак конца командной строки
    je cmdEnd
    
    cmp [si], ' '
    jne copy
       
ENDM 

.model small

.data 

eof db 0

MAX_PATH equ 261
progPath db MAX_PATH dup(0)
  
fopenError db 09h,"An error occurred while opening file: ",'$' 
freadError db 09h,"An error occurred while reading file: ",'$' 
execErr db 09h,"An error occurred while starting another programm: ",'$'
cmdError db 09h,"Could't get file name from cmd arguments",'$'
fileNotFound db "file not found.",'$'
pathNotFound db "path not found.",'$'
2ManyFiles db "too many files opened.",'$'
accessDenied db "access denied.",'$'
invalidAccessMode db "invalid access mode.",'$' 
wrongHandle db "wrong handle.",'$'  
notEnoughMem db "not enough memory.",'$'  
wrongSur db "wrong surrounding.",'$' 
wrongFormat db "wrong format.",'$' 

fileName db 126 dup(0) 

readLEN dw 1                   
file dw 0  

command_line db 0, 0 

epb dw 0
	dw offset command_line,0
	dw 005Ch,0,006Ch,0  
	
DataSize=$-eof	

.stack 100h

.code

main:      
    ;Изменение размера памяти
    mov ah, 4Ah
	mov bx, ((CodeSize/16)+1)+((DataSize/16)+1)+32
	int 21h
    
    mov ax, @data 
    mov es, ax 
    
    ;Получение имени файла из cmd
    call getFileName
    
    mov ds, ax
      
    ;Проверка получения имени файла
    call checkName      
    
    ;Открыть файл
    mov dx, offset fileName
    call openFileR
    mov file, ax 
    
    nextProgramm: 
    call clearPath              ;Очистить путь
    call getProgPath            ;Получить путь из файла

    ;Загрузить и выполнить программу
    mov ax, 4B00h
    mov dx, offset progPath 
    mov bx, offset epb
    int 21h
    jc execError
    
    cmp eof, 0
    je nextProgramm
    
    jmp closeFile

;Ошибка при открытии файла
openFail:
    
    outputString fopenError         
    
    ;Файл не найден
    cmp ax, 02h   
    jne not2
    outputString fileNotFound
    jmp closeFile     
    
not2: 
    ;Путь не найден 
    cmp ax, 03h 
    jne not3  
    outputString pathNotFound
    jmp closeFile      
    
not3:  
    ;Открыто слишком много файлов
    cmp ax, 04h
    jne not4   
    outputString 2ManyFiles
    jmp closeFile
    
not4:
    ;Отказано в доступе
    cmp ax, 05h
    jne not5 
    outputString accessDenied
    jmp closeFile      
    
not5: 
    ;Некорректный режим доступа
    outputString invalidAccessMode
           
;Закрытие файла           
closeFile:    
    closeFile file                 

exit:
    ;Завершение работы
    mov ah, 4Ch
    int 21h 

;Ошибка при чтении    
failedReading: 

    outputString freadError
    cmp ax, 05h
    jne skip 
    
    ;Отказано в доступе 
    outputString accessDenied
    jmp closeFile
     
    skip: 
    ;Некорректный идентификатор
    outputString wrongHandle
    jmp closeFile
    
namesNotFound:  
    ;Пустая командная строка
    outputString cmdError
    jmp exit   
    
execError:

    outputString execErr
        
    ;Файл не найден
    cmp ax, 02h   
    jne not2e
    outputString fileNotFound
    jmp closeFile     
    
not2e: 
    ;Запрещен доступ
    cmp ax, 05h 
    jne not5e 
    outputString accessDenied
    jmp closeFile      
    
not5e:  
    ;Недомтаточно памяти
    cmp ax, 08h
    jne not8e   
    outputString notEnoughMem
    jmp closeFile
    
not8e:
    ;Неправильное окружение
    cmp ax, 0Ah
    jne notAe 
    outputString wrongSur
    jmp closeFile      
    
notAe: 
    ;Некорректный формат
    outputString wrongFormat
    jmp closeFile 


;Получение слова из командной строки
getFileName proc
    pusha
		
	mov si, 82h             ;Начало командной строки
	
    skipSpaces si           ;Пропуск пробелов
	
	copyWord fileName       ;Считывание слова
	
	cmdEnd:	    
    popa
    ret
endp
 
;Открыть файл в режиме только чтение 
openFileR proc 
    xor cx, cx 
    xor al, al
    mov ah, 3dh
    mov al, 00h 
    int 21h 
    jc openFail   
    ret    
endp  

;Проверка считывания имени файла из командной строки
checkName proc    
    cmp [filename], 0
    je namesNotFound
    ret
endp

;Чтение одной строки из файла
getProgPath proc
    pusha
    
    mov di, offset progPath
    dec di
    
    reading:
    inc di
    readFile file
    jc failedReading
    ;Прочитано 0 символов - конец файла
    cmp ax, 0
    je eoff
    
    cmp [di], 0Dh
    je lineEnd
    
    jmp reading
    
    lineEnd:
    mov [di], 0
    
    ;Пропуск 1 символа в файле 
    mov dx, 1
    xor cx, cx 
    mov bx, file
    mov al, 01h
    mov ah, 42h
    int 21h
         
    popa
    ret
    
    eoff:
    inc eof
    popa
    ret
endp 

;Зануление пути исполняемой программы
clearPath proc
    mov di, offset progPath
    mov al, 0
    mov cx, MAX_PATH
    
    rep stosb
    ret        
endp 

CodeSize = $ - main

end main
