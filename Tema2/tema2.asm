extern puts
extern printf

section .data
filename: db "./input.dat",0
inputlen: dd 2263
fmtstr: db "Key: %d",0xa,0

section .text
global main

; TODO: define functions and helper functions

;Aceasta functie primeste adresa de inceput a unui sir si returneaza
;in eax adresa urmatorului sir 
calculate_next_adress:
    push ebp
    mov ebp, esp
    
    push ecx ; punem ecx pe stiva pentru a evita eventuale alterari in functia scasb
    cld              ; setăm DF = 0
    xor eax, eax
    mov al, 0
    mov edi, [ebp+8]
    repne scasb     
    
    mov eax, edi ; stocam in eax adresa urmatorului sir
    pop ecx
    leave
    ret
    
xor_strings:
    push ebp
    mov ebp, esp
    
    mov eax, [ebp+8] ;cheia
    mov ebx, [ebp+12] ;sirul
    
xor_operation:

    mov dl, byte [eax]
    mov dh, byte [ebx]
    cmp dh, 0
    je exit_from_xor_operation ; parasim bucla de xor intre siruri cand ajungem la final
    
    xor dh, dl   ; facem xor octet cu octet
    mov [ebx], dh ; reactualizam 
    inc eax     ;update la adresa sirurilor
    inc ebx
    jmp xor_operation
    
exit_from_xor_operation:    
    leave
    ret
;------------------------------------------------------------------- 
rolling_xor:
    push ebp
    mov ebp, esp
    
    mov ebx, [ebp+8]
    
    xor edx, edx
    mov dl, [ebx]
    inc ebx
    push ecx ;salvez valoarea inceputului sirurilor pe stiva
rolling_xor_operation:
        
    mov dh, [ebx] ; iau caracterul codat
    cmp dh, 0     ; verific daca am ajuns la final , caz in care parasesc functia
    mov cl, dh    ; salvam fostul caracter pentru a-l utiliza la decodarea 
                  ; la a caracterului urmator
    je exit_from_rolling_xor
    
    xor dh, dl      ; decodarea propriuzisa
    mov [ebx], dh   ; actualizez 
    mov dl, cl
    inc ebx       
         
    jmp rolling_xor_operation
    
exit_from_rolling_xor:        
    pop ecx ; restaurez ecx - ul
    leave
    ret

;----------------------------------------------------------
;Aceasta functie primeste ca parametru valoarea unui registru si converteste
;o valoare text in valoarea numerica pt registrii dh si dl 
convert_from_hex:
    push ebp
    mov ebp, esp
    mov edx, [ebp+8]
    
    cmp dl, '9'
    jg litera
    cmp dl, '0'
    jl invalid_result
    sub dl, 48 ;Daca este cifravaloarea este cu 48 mai mica decat valoarea in ascii
    jmp invalid_result
   
litera:
    sub dl, 87 ; Daca este litera valoarea este cu 87 mai mica decat valoarea in ascii
    
invalid_result:
    cmp dh, '9' ; Operatiile de sus executat si pentru dh
    jg litera2
    cmp dh, '0'
    jl invalid_result2
    sub dh, 48
    jmp invalid_result2
   
litera2:
    sub dh, 87
invalid_result2:
    leave 
    ret

xor_hex_strings:
    
    push ebp
    mov ebp, esp 
    mov esi, [ebp+8] ; sirul criptat
    mov edi, [ebp+12] ; cheia
    
    ;Calculez lungimea sirului criptat      
    mov eax, esi
    sub eax, edi
    xor edx, edx    
    mov ecx, 2 ; impart la 2 deoarece fiecarei litere ii corespunde 2 octeti
    div ecx
    ;Stochez in ecx adresa sirului criptat pentru a 
    ;efectua simultan cu conversia si scrierea
    mov ecx, [ebp+8]
    
xor_on_strings_operations:
    ;Salvez de fiecare data temporar pe stiva valorile 
    ;adresei curente din sir unde se face scrierea(ecx)
    ;si numarul de litere ca mai sunt de scris(eax)
    push eax
    push ecx
    ;Iau din memorie primele 2 caractere hex ce pot fi stocate pe un octet
    ;Urmand sa fac conversia din baza 16 in baza 10
    mov ah, [edi]
    mov al, [edi+1]
    ;Ele au codul ascii corespunzator asa ca doresc sa obtin valoarea numerica
    ;Realizez acest lucru cu ajutorul functiei auxiliare declarate mai sus
    push eax
    call convert_from_hex
    add esp, 4
    mov eax, edx ; rezultatul functiei este retinut in edx
    
    ;Procedez identic pentru cheie (Si ea trebuie convertita din hex)
    mov bh, [esi]
    mov bl, [esi+1]
   
    push ebx
    call convert_from_hex
    add esp, 4
    mov ebx, edx ; rezultatul functiei este reitnut in edx
    ;Odata ce am valorile numerice corespunzatoare fac conversia din baza 16 in baza 10
    ;Inmultesc cu 16 pentru prima "cifra" a numarului
    shl ah, 4
    shl bh, 4
    ;Numarul convertit il retin in al ( numarul convertit din baza 16 in 10)
    add al, ah
    add bl, bh
    ;Fac xor intre cele 2 numere convertite
    xor bl, al
    ;Actualizez adresele sirurilor
    add edi, 2
    add esi, 2
    ;Iau de pe stiva pentru valorile pentru a face scriere caracterului decodat
    ;Si pentru a verifica daca mai trebuie sa continui 
    pop ecx
    mov [ecx], bl
    inc ecx
    pop eax
    ;Cat timp mai am caractere de decodat continui
    dec eax
    cmp eax, 0
    jne xor_on_strings_operations
    
    ;Adaug la finalul sirului decodat null-terminatorul
    mov [ecx], byte 0
   
    leave
    ret

;---------------------------------------------------------------------------   
base32decode:
    push ebp
    mov ebp, esp 
    
    mov edi, [ebp+8]

    ;Aloc spatiu pe stiva pentru variabile de un octet
    ;Acestea vor reprezenta caracterele codului(A-Z 2-7)
    ;Iar valoarea lor efectiva A-0 va fi dedusa cu ajutorul
    ;deplasamantului fata de esp
    sub esp, 32
    ;edx variabila auxiliara pentru codurile ascii propriuzisa 
    ;corespunzatoare literelor mari(90-Z)
    mov edx, 90
    mov ecx,25 
    ;Pozitia 26 are litera z , 25 - y ... (Le pun in ordine inversa)
    mov esi, ebp
    sub esi, 26
construire_alfabet:
    
     mov [esi], dl
     inc esi
     dec dl                                      
     dec ecx        ;Cat timp nu am pus cele 26 de litere execut operatia
     cmp ecx, -1
     jne construire_alfabet    
     ;Ultimele pozitii sunt ocupate de caracterele ascii corespunzatoare numerelor
     ;de la 2 la 7
     mov [ebp-27], byte 50 ; codul ascii pentru 2 
     mov [ebp-28], byte 51 ; codul ascii pentru 3
     mov [ebp-29], byte 52
     mov [ebp-30], byte 53
     mov [ebp-31], byte 54
     mov [ebp-32], byte 55   
     
     xor edx, edx
citire_octet:
    mov dl, [edi]
    inc edi
    
    xor eax, eax
    mov esi, ebp ; Adresa finalului tabelului nostru de decodare
    ;Caut in tabel valoarea corespunzatoare , CARACTERULUI STOCAT IN dl
    mov ecx,0
    ;Caut codul literei curente in tabelul nostru
    ;Adresa sfarsitului tabelului stocata in esi
cauta_cod_tabel:
    inc ecx
    dec esi
    mov al, [esi] ; Iau codul asciii 
    cmp al, dl    ;Daca se suprapune cu litera curenta din sir
    je am_gasit_codul
    cmp cl, 33      
    jl cauta_cod_tabel

am_gasit_codul:        
    mov al, dl ; copiez litera din codul codificat pentru a verifica daca am ajuns la final
               ;deoarece valoare lui dl va fi alterata pentru a efectua conversia
               ;pe 5 biti in baza 2 ( valoarea ficarui bit va fi stocata pe un octet de pe stiva)
               ;(va fi 0 sau 1 in functie de caz)
    mov dl, cl
    dec dl ; decrementam deoarece numaratoarea in tabel se incepe de la 0
            ;iar in implementarea mea incepe de la 1
    ;Aloc pentru fiecare caracter "decodat" cu ajutorul tabelei 
    ;5 octeti pe stiva , in fiecare octet fiind stocat bitul corespunzator
    ;reprezentarii numarului din tabela in baza 2 ( conform cu metoda prezentata in enunt)   
    sub esp, 5
    mov esi, esp    ;bitii se pune de la dreapta la stanga( de la cel 
                    ;mai putin semnificativ bit la cel mai semnificativ)
    dec esi     
    mov ecx, 5 
    ;Convertesc numarul in baza 2 ( orice cod are nevoie de maxim 5 biti
    ;pentru a fi reprezentat in baza 2 ( val max 31)  
convert_to_binary:    
    inc esi
    shr dl, 1 ; daca restul impartirii la 2 este 1 atunci cf este setat ) altfel este 0
    jnc pune_zero
    mov [esi],byte  1
    jmp final_operation
pune_zero:
    mov [esi], byte 0
final_operation:
    dec ecx
    jnz convert_to_binary

    cmp al, 0  ;In al este salvat la fiecare caracterul 
                ;pentru a sti cand am citit tot sirul ( atunci cand am terminat de 
                ;'decodat' si null terminatorul
    je iesire_din_bucla

    jmp citire_octet
    
 
iesire_din_bucla:
    mov esi, ebp    ;in esi ma pozitionez la inceputul tabelei unde am codate 
                    ;caracterele ( 32 de caractere)
    sub esi, 33
    xor eax, eax
    mov al, [esi]
    
    mov edi, [ebp+8]  ; edi va stoca adresa inceputului de sir unde efectuez scrieserea
    
    ;Scriu fiecare caracter decodat la adresa lui edi , pana nu am intarnit caracterul "NUL-TERMINATOR"
    ;Am "decodat" si acest caracter pentru a sti cand sa ma opresc din scrierela acest pas
scrie_mesajul:
    ;In ebx vom stoca la fiecare pas suma a 8 biti
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    mov eax, 0  ;   cu ajutorul lui eax realizez bucla in care convertesc fiecare 8 biti
converteste_un_octet:
   
    mov bl, [esi] ; iau fiecare octet de pe stiva in ordinea ceruta
    mov ecx, 7
    sub ecx, eax ; cu ajutorul lui ecx voi determina cu ce putere a lui 
                 ; 2 trebuie inmultit bitul pentru a realiza o conversie corecta
    
    shl bl, cl      
    add dl, bl 
    sub esi, 1
    inc eax
    cmp eax, 8
    jl converteste_un_octet
    ;Cand se iese din bucla de mai sus avem determinata valoarea caracterului
    ;la pasul curent
    mov [edi], dl ;scrierea efectiva
    inc edi
    ;Cat timp nu am scris si caracterul null , executa pasii de mai sus
    cmp dl, 0
    jnz scrie_mesajul
                                                                                                                                                                                                                                                                                                                                     
    leave
    ret                
;----------------------------------------------                                

;Aceasta este o functie auxiliara pentru a determina cheia secreta
;Care se poate determina progrmatic incercand fiecare cheie de la 00 la ff
;pana cand vom gasi in sirul dat cuvantul force
find_secret_key:
    push ebp
    mov ebp, esp
    
    mov edi, [ebp+8]
    xor ebx, ebx
    xor edx, edx
    xor eax, eax
    xor ecx, ecx
       
    mov dl, 0 ; cheia initiala 
cauta_force:
    mov edi, [ebp+8] ;Iau de fiecare data inceputul sirului
    
cauta_in_sir:
    mov cl, [edi+5] ; Daca am ajuns la finalul sirului si nu am gasit cuvantul 
    cmp cl, 0
    jz nedeterminare_cuvant
    
    mov cl, [edi]
    xor cl, dl
    cmp cl, 'f'
    jne nepotrivire_pattern
    
    mov cl, [edi+1]
    xor cl, dl
    cmp cl, 'o'
    jne nepotrivire_pattern
    
    mov cl, [edi+2]
    xor cl, dl
    cmp cl, 'r'
    jne nepotrivire_pattern
    
    mov cl, [edi+3]
    xor cl, dl
    cmp cl, 'c'
    jne nepotrivire_pattern
    
    mov cl, [edi+4]
    xor cl, dl
    cmp cl, 'e'
    jne nepotrivire_pattern
    ;Daca am trecut de toti pasii de mai sus reprezinta faptul ca am gasit
    ;cuvantul folosind cheia curenta 
    jmp cheie_gasita
          
nepotrivire_pattern:    
    ;Cat timp nu am ajuns la finalul sirului continui sa caut cuvantul cu cheia curenta
    inc edi
    jmp cauta_in_sir    
    ;End cauta_in_sir
nedeterminare_cuvant:
    inc dl ; Se pare ca nu am gasit cuvantul cu cheia , de la pasul curent
           ;Asa ca trec la urmatoarea
    jmp cauta_force

cheie_gasita:
    mov bl, dl   ;Retin valoarea cheii in registrul ebx 
    leave
    ret
    
bruteforce_singlebyte_xor:
    push ebp
    mov ebp, esp
    mov edi, [ebp+8] ; sirul
    mov ebx, [ebp+12];cheia
    xor edx, edx ; voi folosit reg edx pentru a executa op cu ajutorul lui
efective_decript:
    mov dl, [edi]
    cmp dl , 0
    jz sir_decodat
    
    xor dl, bl ; fac xor cu cheia pe un octet
    mov [edi], dl ; update la noul caracter 
    inc edi
    jmp efective_decript  

sir_decodat:
    
    leave 
    ret    

;---------------------------------------------
;Construim tabela de substitutie 
build_table:
    push ebp
    mov ebp, esp
 
    mov edi, [ebp+8] ; iau de pe stiva primul argument
                     ;Si pun pe pozitiile pare caracterele alfabetului initial
    mov ecx, 26
    xor edx, edx
    mov dl, 97      ;Codul ascii pentru a
put_the_alphabet:
    mov [edi], dl 
    add edi, 2
    inc dl     ;Urmatorul cod ASCII
    dec ecx
    jnz put_the_alphabet
    mov [edi],byte 32    ;Codul ascii pentru space
    mov[edi+2],byte  46  ;Codul Ascii pentru punct
    
    sub esp, 56 ; Rezerv spatiu pe stiva pentru o tabela
                ;auxiliara, impropriu spus tabela, pentru a determina frecventa fiecarui
                ;caracter din sirul (CODAT)
    mov edi, esp
    mov ecx, 56 ; 56 de caractere in total in tabela de substitutie
    mov al, 0   ;Zeroizez toata zona , pentru ca este posibil sa fie date nedorite
                ;pe adresele din stiva pe care le am decodat
    rep stosb 
    
    mov edi, esp
    mov esi, [ebp+12] ;sirul de decodat
    
    
    xor edx, edx
    xor ebx, ebx
    xor ecx, ecx
calcul_frecvente:
    mov dl, [esi]
    inc esi
    cmp dl , 0
    je iesi_din_calcul_frecvente
    
    cmp dl, 32
    je space            ;Salt la labelul unde numar space-urile
    cmp dl, 46
    je punct            ;salt la labelul unde numar punctele
    
    ;Edx are salvat in el caracterul curent
    ;Iar contorul se afla la 2 * pozitia din alfabet( pt a-0, b-2, c-4)                     
    sub edx, 97
    shl edx, 1          
    
    mov eax, edi        ;retinem eax inceputul adresei vectorului de frecventa
    add eax, edx        ;Adunam valoarea lui edx , pentru a aduna apaaritia curenta
                        ;la celula corespunzatoare
    inc eax                 
    add [eax], byte 1 
    jmp calcul_frecvente
space:
    add [edi+53], byte 1
    jmp calcul_frecvente
punct:
    add [edi+55], byte 1
    jmp calcul_frecvente
 
iesi_din_calcul_frecvente:   
    mov edi, esp
    add edi, 1
    mov ecx, 1      ;Aceasta bucla a fosta necesara atunci cand a trebuit sa ma uit
                    ;Eu sa vad care este numarul de aparitii pentru fiecare caracter
                    ;Dupa crearea tabelei de substitutie , momentan nu mai este nevoie
                    ;Dar am lasat o aici deoarece este nevoie de aceasta secventa de cod
                    ;Intrucat este unul din pasii cu ajutorul caruia am format aceasta tabela
verifica_frecvente:
    mov dl, [edi]
    add edi, 2
    inc ecx
    cmp ecx, 29
    jl verifica_frecvente        
    
    mov esi, [ebp+8]
    add esi, 1
   
    mov [esi], byte 'q'       ;a
    mov [esi + 2] , byte 'r'  ;b 
    mov [esi + 4], byte 'w'   ;c
    mov [esi + 6], byte 'e'   ;d
    mov [esi + 8], byte ' '   ;e 
    mov [esi + 10], byte 'u'  ;f
    mov [esi + 12], byte 't'  ;g
    mov [esi + 14], byte 'y'  ;h
    mov [esi + 16], byte 'i'  ;i
    mov [esi + 18], byte 'o'  ;j
    mov [esi + 20] , byte 'p' ;k
    mov [esi + 22], byte 'f'  ;l
    mov [esi + 24], byte 'h'  ;m
    mov [esi + 26], byte '.'  ;n
    mov [esi + 28], byte 'g'  ;o
    mov [esi + 30], byte 'd'  ;p
    mov [esi + 32], byte 'a'  ;q
    mov [esi + 34], byte 's'  ;r
    mov [esi + 36], byte 'l'   ;s
    mov [esi + 38], byte 'k'  ;t
    mov [esi + 40], byte 'm'  ;u
    mov [esi + 42], byte 'j'  ;v
    mov [esi + 44], byte 'n'  ;w
    mov [esi + 46], byte 'b'  ;x
    mov [esi + 48], byte 'z'  ;y 
    mov [esi + 50], byte 'v'  ;z
    mov [esi + 52], byte 'c'  ;space
    mov [esi + 54], byte 'x'  ;pct 
               
    leave
    ret
    
break_substitution:
    push ebp
    mov ebp, esp
    
    mov edi, [ebp+8]   ;encoded messege
    mov esi, [ebp+12]   ;substituion table
    xor edx, edx
    xor ecx, ecx
    xor ebx, ebx
execute_substitution:
    mov dl, [edi]
    inc edi
    
    cmp dl, 0
    je iesire_din_executie ; conditia de exit
       
    mov esi, [ebp+12] ; incarcam tabela de substitutie si cautam caracterul sa vedem pe cine inlocuieste
    inc esi
cauta_in_tabela:
    
    mov bl, [esi]
    add esi, 2
    cmp bl, dl
    jne cauta_in_tabela
    mov bl, [esi-3] ; copiem caracterul ce este substituit litera curent a textului
    mov [edi-1], bl ; si o punem pe locul corespunzator
    jmp execute_substitution
    
iesire_din_executie:
   
    leave
    ret    
    
main:
    mov ebp, esp; for correct debugging
    push ebp
    mov ebp, esp
    sub esp, 2300
    
    ; fd = open("./input.dat", O_RDONLY);
    mov eax, 5
    mov ebx, filename
    xor ecx, ecx
    xor edx, edx
    int 0x80
    
	; read(fd, ebp-2300, inputlen);
	mov ebx, eax
	mov eax, 3
	lea ecx, [ebp-2300]
	mov edx, [inputlen]
	int 0x80

	; close(fd);
	mov eax, 6
	int 0x80
          
	; all input.dat contents are now in ecx (address on stack)

	; TASK 1: Simple XOR between two byte streams
	; TODO: compute addresses on stack for str1 and str2
	; TODO: XOR them byte by byte
	;push addr_str2
	;push addr_str1
	;call xor_strings
	;add esp, 8
    
        push ecx
        call calculate_next_adress
        add esp, 4    
        
        push ecx
        push eax
        call xor_strings
        pop eax
        pop ecx
	; Print the first resulting string
	;push addr_str1
	;call puts
	;add esp, 4
        push eax
        push ecx
        push ecx
        call puts
        add esp, 4
        pop ecx
        pop eax
        
	; TASK 2: Rolling XOR
	; TODO: compute address on stack for str3
	; TODO: implement and apply rolling_xor function
	;push addr_str3
	;call rolling_xor
	;add esp, 4
        push eax
        call calculate_next_adress
        add esp, 4 ;the result stored in eax     
        push eax
        call rolling_xor
        pop eax
        
       	; Print the second resulting string
	;push addr_str3
	;call puts
	;add esp, 4
        push ecx
        push eax
        call puts
        pop eax ;fac pop pentru a nu modifica registrii
        pop ecx

	
	; TASK 3: XORing strings represented as hex strings
	; TODO: compute addresses on stack for strings 4 and 5
	; TODO: implement and apply xor_hex_strings
        
        ;Computing the addr_str4
        push eax
        call calculate_next_adress
        add esp, 4 ;the result stored in eax
        mov ecx, eax
        
        ;Computing the addr_str5
        push ecx
        call calculate_next_adress
        add esp, 4 ; the result stored in eax
        

	;push addr_str5
	;push addr_str4
	;call xor_hex_strings
	;add esp, 8
       
        push ecx
        push eax
        call xor_hex_strings
        pop eax ;inlocuiesc add-ul cu pop uri 
        pop ecx ;pentru a evita erori din cauza posibilelor
                ;alterari ale registrelor eax si ecx in functie
              
                     
	; Print the third string
	;push addr_str4
	;call puts
	;add esp, 4
        push ecx
        push eax
        call puts
        pop eax
        pop ecx  
	
	; TASK 4: decoding a base32-encoded string
	; TODO: compute address on stack for string 6
	; TODO: implement and apply base32decode
	;push addr_str6
	;call base32decode
	;add esp, 4

        ;Compute address addr_str6
        ;save the last address to calculate the length of the encoded messege
       
        
        push eax
        call calculate_next_adress
        add esp, 4 ; the result stored in eax
        
        push eax
        call calculate_next_adress
        add esp, 4 ; the result stored in eax
       
        push eax
        call base32decode
        pop eax
        
	; Print the fourth string
	;push addr_str6
	;call puts
	;add esp, 4
        ;Afisez mesajul pe care tocmai l am decodat 
        push eax
        call puts
        pop eax

        ; TASK 5: Find the single-byte key used in a XOR encoding
	; TODO: determine address on stack for string 7
	; TODO: implement and apply bruteforce_singlebyte_xor
	;push key_addr
	;push addr_str7
	;call bruteforce_singlebyte_xor
	;add esp, 8
        
        ;Apelul functiei de mai jos va ajunge la finalul sirului suprascris , care nu este
        ;inceputul sirului7 ci este doar o parte a sirului de la exercitiul anterior care 
        ;nu a fost suprascris
        push eax
        call calculate_next_adress
        add esp, 4 ; the result stored in eax 
                
        push eax
        call calculate_next_adress
        add esp, 4 ; the result stored in eax
        
        push eax
        call find_secret_key
        pop eax ; cheia secreta se afla stocata in ebx
              
        push ebx ; punem cheia pe stiva ( desi cheia este stocata doar in bl)
        push eax ; punem sirul de cautat
        call bruteforce_singlebyte_xor
        pop eax
        pop ebx
          
        	; Print the fifth string and the found key value
	;push addr_str7
	;call puts
	;add esp, 4
        push ebx
        push eax
        call puts
        pop eax
        pop ebx

	;push keyvalue
	;push fmtstr
	;call printf
	;add esp, 8

        push eax ; punem pe stiva eaxpentru ca e posibil sa fie alterata adresa 
                 ;in timpul apelului functiei printf
        push ebx
        push fmtstr
        call printf
        add esp, 8
        pop eax ; luam de pe stiva valoarea lui eax
            
	; TASK 6: Break substitution cipher
	; TODO: determine address on stack for string 8
	; TODO: implement break_substitution
	;push substitution_table_addr
	;push addr_str8
	;call break_substitution
	;add esp, 8

        push eax
        call calculate_next_adress
        add esp, 4
        
        sub esp, 1
        mov [esp],byte 0 ; punem pe ultima pozitie null terminatorul( al tabelei)
        sub esp, 56 ; 56 = 2 * 26   + 4(caracterele plus "." si SPACE)
        
        mov ecx , esp ; adresa inceputului tabelei se va retine in ecx
        
        push eax
        push ecx ; salvam ambele adrese pe stiva , pentru a evita anumite alterari ce ar puti innterveni in timpul apelului de functii
        call build_table
        pop ecx
        pop eax
        
       
        push ecx ; substitution table address
        push eax
        call break_substitution
        pop eax
        pop ecx
        
	; Print final solution (after some trial and error)
	;push addr_str8
	;call puts
	;add esp, 4
        
        push ecx
        push eax
        call puts
        pop eax
        pop ecx
        

	; Print substitution table
	;push substitution_table_addr
	;call puts
	;add esp, 4

        push eax
        push ecx
        call puts
        pop ecx
        pop eax

	; Phew, finally done
    xor eax, eax
    leave
    ret
