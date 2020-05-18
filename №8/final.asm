.model tiny
.code
.org 100h

start:  
    jmp main

;Àäðåñà ñòàðûõ ïðåðûâàíèé
oldTimerHandler dd 0
oldKeyboardHandler dd 0  

delay dw 0                          ;Çàäåðæêà â ñåêóíäàõ  
current dw 0                        ;Ïðîøåäøåå âðåìÿ
ticks db 18
saving db 0                         

;Íîâîå ïðåðûâàíèå òàéìåðà
timerHandler proc far
    pushf 
    ;Ñòàðûé îáðàáîò÷èê
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

;Íîâîå ïðåðûâàíèå êëàâèàòóðû
keyboardHandler proc far
    pushf  
    ;Ñòàðûé îáðàáîò÷èê
    call dword ptr cs:oldKeyboardHandler
    
    pusha
    push es
    push ds
    push cs
    pop ds
    
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

;Ïðîöåäóðà ñìåíû èçîáðàæåíèÿ íà ýêðàíå
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
    call getDelay                   ;Ïîëó÷åíèå çàäåðæêè èç êîìàíäíîé ñòðîêè
    
    cmp delay, 0
    je incorrectInput
    
    mov ax, delay
    mov current, ax
     
    cli 
        
        ;Ïîëó÷åíèå ñòàðîãî ïðåðûâàíèÿ òàéìåðà
        mov al, 1Ch
        mov ah, 35h
        int 21h 

        mov WORD PTR oldTimerHandler, bx
        mov WORD PTR oldTimerHandler + 2, es
        
        ;Ïåðåîïðåäåíèå ïðåðûâàíèÿ òàéìåðà
        mov dx, offset timerHandler
        mov al, 1Ch
        mov ah, 25h
        int 21h 
         
        ;Ïîëó÷åíèå ñòàðîãî ïðåðûâàíèÿ êëàâèàòóðû
        mov al, 09h
        mov ah, 35h
        int 21h 

        mov WORD PTR oldKeyboardHandler, bx
        mov WORD PTR oldKeyboardHandler + 2, es
        
        ;Ïåðåîïðåäåíèå ïðåðûâàíèÿ êëàâèàòóðû
        mov dx, offset keyboardHandler
        mov al, 09h
        mov ah, 25h
        int 21h 
    sti  
    
    mov dx, offset turnoff
    call outputString 
   
    ;îñòàâèòü ïðîãðàììó ðåçèäåíòíîé
    mov ax, 3100h      
    mov dx, (main-start+10Fh)/16
    int 21h           
    
    ;Ïåðåïîëíåíèå
    inputOverflow:
    mov dx, offset overflow
    call outputString
    jmp exit
    
    ;Íåêîððåêòíûé ââîä ÷èñëà          
    incorrectInput:
    mov dx, offset error
    call outputString 
    
    exit:
    mov ax, 4ch
    int 21h
       
getDelay proc
    pusha
    
    mov si, 82h                     ;Íà÷àëî êîìàíäíîé ñòðîêè
    xor ax, ax
    
    converse:   
    mov bx, 0Ah
    mul bx                          ;Óìíîæåíèå àêêóìóëÿòîðà íà 10    
    jo inputOverflow                ;Ïðîâåðêà íà ïåðåïîëíåíèå
    
    mov bl, [si]                    ;Ñèìâîë èç ñòðîêè
    sub bx, '0'                     ;Îòíèìàåì îò ascii êîäà ñèìâîëà ascii êîä íóëÿ
    
    ;Ïðîâåðêà ñèìâîëà íà óñëîâèå 0 <= x <= 9
    cmp bx, 9                       
    jg incorrectInput
    cmp bx, 0
    jl incorrectInput
    
    add ax, bx                      ;Äîáàâëåíèå íîâîãî ðàçðÿäà ê àêêóìóëÿòîðó
    jo inputOverflow                ;Ïðîâåðêà íà ïåðåïîëíåíèå
    
    inc si                          ;Ïåðåõîä ê ñëåäóþùåìó ñèìâîëó
   
    cmp [si], 0Dh                   ;Ïðèçíàê êîíöà êîìàíäíîé ñòðîêè
    jne converse
    
    mov delay, ax
       
    popa  
    ret
getDelay endp 

;Âûâîä ñòðîêè íà ýêðàí
outputString proc
    mov ah, 09h
    int 21h
    ret
outputString endp

error db "Error. Incorrect input! cmd arg should be [1, 32.767]$" 
turnoff db "Info: press Esc to turn screensaver off$" 
overflow db "Error. Input overflow! cmd arg should be [1, 32.767]$"

end start
