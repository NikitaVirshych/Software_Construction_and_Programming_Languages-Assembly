.model small
.stack 100h

.code
jmp main 

;Чтение readLen символов из file в buf
readFile MACRO file, buf  
    mov bx, file 
    mov cx, readLEN 
    mov dx, offset buf
    mov ah, 3Fh
    int 21h    
ENDM     
 
;Сброс указателя чтения
resetFile MACRO file  
    xor cx, cx
    xor dx, dx 
    mov bx, file
    mov al, 00h
    mov ah, 42h
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

;Получение двух слов из командной строки
getFileNames proc
    pusha
		
	mov si, 82h             ;Начало командной строки
	
    skipSpaces si           ;Пропуск пробелов
	
	copyWord firstFileName      ;Считывание первого слова
	
	skipSpaces si           ;Пропуск пробелов
	
	copyWord secondFileName      ;Считывание второго слова
	
	cmdEnd:	    
    popa
    ret
endp

;Сброс указателей чтения обоих файлов
resetFiles proc
    pusha    
    resetFile firstFile 
    resetFile secondFile  
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

 
;Сравнение фалов по содержимому 
cmpFiles proc 
    
    call resetFiles 
    
    comparing:
        
        readFile firstFile, buf1    ;Прочитать символ из 1 файла
        jc failedReading
        ;Прочитано 0 символов - конец файла
        cmp ax, 0
        je eof
       
        readFile secondFile, buf2   ;Прочитать символ из 2 файла
        jc failedReading 
         
        ;Символ конца строки в 1 файле 
        cmp buf1, 0Ah
        je skipNewline
        cmp buf1, 0Dh            
        je skipNewline
    
    cmpSym:
    ;Сравнение символов    
    mov bl, buf1
    cmp bl, buf2
    je comparing
    
    jmp notEqual 
    
    skipNewline: 
    ;Проверка символа конца файла во 2 файле
    cmp buf2, 0Ah
    je skipNewline1
    cmp buf2, 0Dh            
    je skipNewline1 
      
    jmp notEqual
    
    skipNewline1: 
    ;Пропуск символов новой строки в 1 файле
    readFile firstFile, buf1    ;Прочитать символ из 1 файла
    jc failedReading
    ;Прочитано 0 символов - конец файла
    cmp ax, 0
    je skipNewline2
    
    cmp buf1, 0Ah
    je skipNewline1
    cmp buf1, 0Dh            
    je skipNewline1
                        
    skipNewline2: 
    ;Пропуск символов новой строки во 1 файле
    readFile secondFile, buf2   ;Прочитать символ из 2 файла
    jc failedReading
    cmp ax, 0
    je eof
    
    cmp buf2, 0Ah
    je skipNewline2
    cmp buf2, 0Dh            
    je skipNewline2
    
    jmp cmpSym
    
    eof:
    ret      
endp   

;Проверка считывания 2 имён файлов из командной строки
checkNames proc    
    
    cmp [firstFilename], 0
    je namesNotFound
    
    cmp [secondFilename], 0
    je namesNotFound
    
    ret
endp



main:
    mov ax, @data 
    mov es, ax 
    
    ;Получение имён файлов из cmd
    call getFileNames
    
    mov ds, ax  
    
    ;Проверка получения имён файлов
    call checkNames   
    
    ;Открыть первый файл
    mov dx, offset firstFileName
    call openFileR
    mov firstFile, ax 
                  
    ;Открыть второй файл                 
    mov dx, offset secondFileName
    call openFileR
    mov secondFile, ax
     
    ;Сравнить файлы по содержимому
    call cmpFiles   
    
    ;Файлы равны
    outputString equal
    
    jmp closeFiles

;Ошибка при открытии файла
openFail:
    
    outputString fopenError         
    
    ;Файл не найден
    cmp ax, 02h   
    jne not2
    outputString fileNotFound
    jmp closeFiles     
    
not2: 
    ;Путь не найден 
    cmp ax, 03h 
    jne not3  
    outputString pathNotFound
    jmp closeFiles      
    
not3:  
    ;Открыто слишком много файлов
    cmp ax, 04h
    jne not4   
    outputString 2ManyFiles
    jmp closeFiles
    
not4:
    ;Отказано в доступе
    cmp ax, 05h
    jne not5 
    outputString accessDenied
    jmp closeFiles      
    
not5: 
    ;Некорректный режим доступа
    outputString invalidAccessMode
           
;Закрытие файлов           
closeFiles:    
    closeFile firstFile                
    closeFile secondFile 

exit:
    ;Завершение работы
    mov ah, 4Ch
    int 21h 

;Разные размеры    
sizeExit: 
    outputString sizeNEqual
    jmp closeFiles 

;Файлы не равны    
notEqual:
    outputString nEqual
    jmp closeFiles 

;Ошибка при чтении    
failedReading: 

    outputString freadError
    cmp ax, 05h
    jne skip 
    
    ;Отказано в доступе 
    outputString accessDenied
    jmp closeFiles
     
    skip: 
    ;Некорректный идентификатор
    outputString wrongHandle
    jmp closeFiles
    
namesNotFound:
    outputString cmdError
    jmp exit
    

.data  
   
equal db "Files are equal.",'$'
nEqual db "Files aren't equal.",'$'

fopenError db 09h,"An error occurred while opening file: ",'$' 
freadError db 09h,"An error occurred while reading file: ",'$'
cmdError db 09h,"Could't get file names from cmd arguments",'$'
fileNotFound db "file not found.",'$'
pathNotFound db "path not found.",'$'
2ManyFiles db "too many files opened.",'$'
accessDenied db "access denied.",'$'
invalidAccessMode db "invalid access mode.",'$' 
sizeNEqual db "File sizes aren't equal.",'$'
wrongHandle db "wrong handle.",'$'  

firstFileName db 126 dup(0)
secondFileName db 126 dup(0)

buf1 db 0
buf2 db 0 

readLEN dw 1                   
firstFile dw 0
secondFile dw 0 

end main
