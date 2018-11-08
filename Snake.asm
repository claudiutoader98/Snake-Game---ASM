.386
.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Snake",0
area_width EQU 700
area_height EQU 516
area DD 0
restart DD 0
direction DD 1
counter DD 0 ; numara evenimentele de tip timer
counter_sec DD 0
i_start DD 250
j_start DD 249
scor DD 0
high_score DD 0

i DD 250
j DD 249
index DD 18
index_vector DD 3
compare DD 0
snake_x DD 20,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
snake_y DD 20,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1 

food_x DD 250
food_y DD 372
click_x DD 0
click_y DD 0
contor DD 0
game_over DD 0
format_intreg DB "%d ",0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

make_text proc
	push EBP
	mov EBP, ESP
	pusha
	
	mov EAX, [EBP+arg1] ; citim simbolul de afisat
	cmp EAX, 'A'
	jl make_digit
	cmp EAX, 'Z'
	jg make_digit
	sub EAX, 'A'
	lea ESI, letters
	jmp draw_text
make_digit:
	cmp EAX, '0'
	jl make_space
	cmp EAX, '9'
	jg make_space
	sub EAX, '0'
	lea ESI, digits
	jmp draw_text
make_space:	
	mov EAX, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea ESI, letters
	
draw_text:
	mov EBX, symbol_width
	mul EBX
	mov EBX, symbol_height
	mul EBX
	add ESI, EAX
	mov ECX, symbol_height
bucla_simbol_linii:
	mov EDI, [EBP+arg2] ; pointer la matricea de pixeli
	mov EAX, [EBP+arg4] ; pointer la coord y
	add EAX, symbol_height
	sub EAX, ECX
	mov EBX, area_width
	mul EBX
	add EAX, [EBP+arg3] ; pointer la coord x
	shl EAX, 2 ; inmultim cu 4, avem un DWORD per pixel
	add EDI, EAX
	push ECX
	mov ECX, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [ESI], 0
	je simbol_pixel_alb
	mov dword ptr [EDI], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [EDI], 0555555h
simbol_pixel_next:
	inc ESI
	add EDI, 4
	loop bucla_simbol_coloane
	pop ECX
	loop bucla_simbol_linii
	popa
	mov ESP, EBP
	pop EBP
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add ESP, 16
endm

make_lines macro x, y, line_lenght
    mov ECX, line_lenght; lungimea liniei 
	mov ESI, x ; i 
	mov EDI, y ; j
	mov EBX, area ; pointer la primul element din matrice 
endm 

n_of_pixels macro 
    mov EAX, area_width
    mul ESI
    add EAX, EDI
endm

vertical_line macro x, y, lenght, colour
    LOCAL draw_line1
    make_lines x, y, lenght
draw_line1:
    n_of_pixels 
    mov dword ptr[EBX+EAX*4], colour
	mov dword ptr[EBX+EAX*4+4], colour
	mov dword ptr[EBX+EAX*4+8], colour
    inc ESI
loop draw_line1
endm 

vertical_line1 macro x, y, lenght, colour
    LOCAL draw_line6
    make_lines x, y, lenght
draw_line6:
    n_of_pixels 
    mov dword ptr[EBX+EAX*4], colour
    inc ESI
loop draw_line6
endm 

horizontal_line macro x , y, lenght, colour
    LOCAL draw_line2
    make_lines x, y, lenght	
draw_line2:
    n_of_pixels 
	mov dword ptr[EBX+EAX*4], colour
	mov dword ptr[EBX+EAX*4+area_width*4], colour
	mov dword ptr[EBX+EAX*4+area_width*4*2], colour
	inc EDI
loop draw_line2
endm

horizontal_line1 macro x , y, lenght, colour
    LOCAL draw_line5
    make_lines x, y, lenght	
draw_line5:
    n_of_pixels 
	mov dword ptr[EBX+EAX*4], colour
	inc EDI
loop draw_line5
endm

oblical_line_left macro x, y, lenght, colour
    LOCAL draw_line3
	make_lines x, y, lenght
draw_line3:
    n_of_pixels
	mov dword ptr[EBX+EAX*4], colour
	dec EDI
	inc ESI
loop draw_line3
endm

oblical_line_right macro x, y, lenght, colour
    LOCAL draw_line4
	make_lines x, y, lenght
draw_line4:
    n_of_pixels
	mov dword ptr[EBX+EAX*4], colour
	inc EDI
	inc ESI
loop draw_line4
endm


draw_button macro x1, x2, y1, y2, lungime, latime, colour
    horizontal_line x1, y1, lungime, colour
	horizontal_line x2, y1, lungime, colour
	vertical_line x1, y1, latime, colour
	vertical_line x1, y2, latime, colour
endm

make_point macro x, y, scalar_i, scalar_j, colour, direction
   pusha 
    mov ESI, x
	mov EDI, y
    mov EBX, area
	
		
	add ESI, scalar_i
	add EDI, scalar_j
	
    mov EAX, area_width
	dec ESI
    mul ESI
    add EAX, EDI
	mov dword ptr[EBX+EAX*4], colour
	mov dword ptr[EBX+EAX*4-4], colour
	mov dword ptr[EBX+EAX*4+4], colour
	
	mov EAX, area_width
	inc ESI
    mul ESI
    add EAX, EDI
	
	mov dword ptr[EBX+EAX*4-4], colour
	mov dword ptr[EBX+EAX*4], colour
	mov dword ptr[EBX+EAX*4+4], colour
	
	mov EAX, area_width
	inc ESI
    mul ESI
    add EAX, EDI
	
	mov dword ptr[EBX+EAX*4-4], colour
	mov dword ptr[EBX+EAX*4], colour
	mov dword ptr[EBX+EAX*4+4], colour
	popa
endm

game_over_macro macro
    make_text_macro 'G', area, 580, 20 
	make_text_macro 'A', area, 600, 20 
	make_text_macro 'M', area, 620, 20 
	make_text_macro 'E', area, 640, 20 
	
	make_text_macro 'O', area, 580, 40 
	make_text_macro 'V', area, 600, 40 
	make_text_macro 'E', area, 620, 40 
	make_text_macro 'R', area, 640, 40 
endm

score_macro macro 
    make_text_macro 'S', area, 590, 120
	make_text_macro 'C', area, 600, 120
	make_text_macro 'O', area, 610, 120
	make_text_macro 'R', area, 620, 120
	make_text_macro 'E', area, 630, 120
endm

high_score_macro macro
    make_text_macro 'H', area, 540, 470
	make_text_macro 'I', area, 550, 470
	make_text_macro 'G', area, 560, 470
	make_text_macro 'H', area, 570, 470
	make_text_macro 'S', area, 590, 470
	make_text_macro 'C', area, 600, 470
	make_text_macro 'O', area, 610, 470
	make_text_macro 'R', area, 620, 470
	make_text_macro 'E', area, 630, 470
endm

make_snake macro x, y, culoare ,direction
    make_point x, y, 0, 0, culoare, direction 
	make_point x, y, -3, -3, culoare , direction
	make_point x, y, -3, 0, culoare , direction
	make_point x, y, -3, 3, culoare, direction
	make_point x, y, 0, 3, culoare , direction
	make_point x, y, 3, 3, culoare , direction
	make_point x, y, 3, 0, culoare, direction
	make_point x, y, 3, -3, culoare, direction
	make_point x, y, 0, -3, culoare , direction
	make_point x, y, -6, -6, culoare, direction
	make_point x, y, -6, -3, culoare, direction
	make_point x, y, -6, 0, culoare, direction
	make_point x, y, -6, 3, culoare , direction
	make_point x, y, -6, 6, culoare, direction
	make_point x, y, -3, 6, culoare , direction
	make_point x, y, 0, 6, culoare, direction
	make_point x, y, 3, 6, culoare , direction
	make_point x, y, 6, 6, culoare , direction
	make_point x, y, 6, 3, culoare , direction
	make_point x, y, 6, 0, culoare , direction
	make_point x, y, 6, -3, culoare , direction
	make_point x, y, 6, -6, culoare, direction
	make_point x, y, 3, -6, culoare, direction
	make_point x, y, 0, -6, culoare, direction
	make_point x, y, -3, -6, culoare , direction
endm
; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y


draw proc
	push EBP
	mov EBP, ESP
	pusha
	
	mov EAX, [EBP+arg1]
	cmp EAX, 1
	jz evt_timer
	cmp EAX, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov EAX, area_width
	mov EBX, area_height
	mul EBX
	shl EAX, 2
	push EAX
	push 0555555h
	push area
	call memset
	add ESP, 12
	
	score_macro
	high_score_macro
	
evt_timer:
	inc counter
	inc counter_sec
afisare_litere:
	
	mov EBX, 10
	mov EAX, scor
	;cifra unitatilor
	mov EDX, 0
	div EBX
	add EDX, '0'
	make_text_macro EDX, area, 620, 140
	;cifra zecilor
	mov EDX, 0
	div EBX
	add EDX, '0'
	make_text_macro EDX, area, 610, 140
	;cifra sutelor
	mov EDX, 0
	div EBX
	add EDX, '0'
	make_text_macro EDX, area, 600, 140
	
	
	mov EBX, 10
	mov EAX, high_score
	;cifra unitatilor
	mov EDX, 0
	div EBX
	add EDX, '0'
	make_text_macro EDX, area, 680, 470
	;cifra zecilor
	mov EDX, 0
	div EBX
	add EDX, '0'
	make_text_macro EDX, area, 670, 470
	;cifra sutelor
	mov EDX, 0
	div EBX
	add EDX, '0'
	make_text_macro EDX, area, 660, 470
	
	mov EDI, [EBP+arg3] ; x
	mov click_x, EDI
	
	mov EDI, [EBP+arg2] ; y
	mov click_y, EDI

right_button:
    cmp click_x, 310
	jl left_button
	cmp click_x, 350 
	jg left_button
    cmp click_y, 638
    jl left_button
    cmp click_y, 692	
	jg left_button
	cmp direction, 3
	je next
	mov direction, 1
	jmp next
left_button:
    cmp click_x, 310
	jl down_button
	cmp click_x, 350 
	jg down_button
    cmp click_y, 526
    jl down_button
    cmp click_y, 579	
	jg down_button
	cmp direction, 1
	je next
	mov direction, 3
	jmp next
down_button:
    cmp click_x, 354
	jl up_button
	cmp click_x, 392
	jg up_button
	cmp click_y, 581
	jl up_button
	cmp click_y, 636
	jg up_button
	cmp direction, 4
	je next
	mov direction, 2
	jmp next
up_button:
    cmp click_x, 270
	jl next
	cmp click_x, 306
	jg next
	cmp click_y, 581
	jl next
	cmp click_y, 636
	jg next
	cmp direction, 2
	je next
	mov direction, 4
next:
    mov EAX, counter_sec
	cmp EAX, 1
	je draw_head
	jmp final_draw
	
draw_head:

    make_snake food_x, food_y, 0f21838h, direction
	
    mov EBX, index
	xor EAX, EAX
    inc EBX
	cmp snake_x[EBX*4], -1
    je shift
	make_snake snake_x[4*EBX], snake_y[4*EBX], 0555555h, direction
shift:
    dec EBX
shift_x:
    mov EAX, snake_x[4*EBX]
	inc EBX
	mov snake_x[4*EBX], EAX
	dec EBX
	dec EBX
	cmp EBX, 0
    jge shift_x
	
	xor EAX, EAX
	mov EBX, index
shift_y:
    mov EAX, snake_y[4*EBX]	
    inc EBX
	mov snake_y[4*EBX], EAX
	dec EBX
	dec EBX
	cmp EBX, 0
	jge shift_y

	cmp direction, 1
	je right
	cmp direction, 2
	je down
	cmp direction, 3
	je left
	cmp direction, 4
	je up

;------------------------RIGHT----------------------------	
right:
   add j, 16
   mov ECX, j
   add ECX, 7
   cmp ECX, area_height
   jl cont1
   mov j, 10
cont1:  
   mov ECX, i
   mov snake_x[0],ECX
	
   mov ECX, j
   mov snake_y[0],ECX

   mov EBX, index 
   add EBX, 2
   mov index_vector, 3
eti1:
   xor EDX, EDX
   xor EDI, EDI
   
   mov EDI, index_vector
   mov EDX, snake_y[4*EDI]
   cmp EDX, -1
   je eat_right
   
   mov contor, 16
repeta1:
   cmp snake_y[0], EDX
   je cmp_x_r
   dec EDX
   dec contor
   cmp contor, 0
jne repeta1
jmp inc_index_r
   
cmp_x_r:
   mov contor, 16
   xor EDX, EDX
   xor EDI, EDI
   mov EDI, index_vector
   mov EDX, snake_x[4*EDI]
r1:
   cmp snake_x[0], EDX
   je game_over_right
   dec EDX
   dec contor
   cmp contor, 0
jne r1

   mov contor, 16
   xor EDX, EDX
   xor EDI, EDI
   mov EDI, index_vector
   mov EDX, snake_x[4*EDI]
r2:
   cmp snake_x[0], EDX
   je game_over_right
   inc EDX
   dec contor
   cmp contor, 0
jne r2

inc_index_r:
   inc index_vector
   cmp index_vector, 18
   jl eti1
jmp eat_right
game_over_right:
    
	xor EBX, EBX
	mov EBX, scor
    cmp EBX, high_score
    jl reset_score_r
	mov high_score, EBX
	

reset_score_r:	
    mov scor, 0
	;-----------------------------------------------
 
    xor EDX, EDX
	mov EDX, -1
delete_snake_right:
   inc EDX
   cmp snake_x[EDX*4], -1
   je delete_snake_right
   make_snake snake_x[4*EDX], snake_y[4*EDX], 0555555h, direction
   cmp EDX, 20
   jl delete_snake_right

    mov EDX, i_start
	mov i, EDX
	mov EDX, j_start
	mov j, EDX
	
    mov snake_x[0], 20
	mov snake_y[0], 20
	xor EDX, EDX
	mov EDX, 1
delete_vector_right:
    mov snake_x[4*EDX], -1
	mov snake_y[4*EDX], -1
	inc EDX
	cmp EDX, 20
jne delete_vector_right
jmp continue

   
eat_right:
   mov contor, 16
   xor EDX, EDX
   mov EDX, food_y
right0:
   cmp snake_y[0], EDX
   je cmp_x_right
   dec EDX
   dec contor
   cmp contor, 0
jne right0
jmp delete_last_r

cmp_x_right: 
   mov contor, 16
   xor EDX, EDX
   mov EDX, food_x
right1:
   cmp snake_x[0], EDX
   je delete_food_r
   dec EDX
   dec contor
   cmp contor, 0
jne right1

   mov contor, 16
   xor EDX, EDX
   mov EDX, food_x
right2:
   cmp snake_x[0], EDX
   je delete_food_r
   inc EDX
   dec contor
   cmp contor, 0
jne right2

delete_last_r:
    dec EBX
	cmp EBX, -1
	je delete_last_right
    mov EAX, snake_x[4*EBX]
	cmp EAX, -1
    je delete_last_r
delete_last_right:
    make_snake snake_x[EBX*4], snake_y[EBX*4], 0555555h, direction
	
    mov snake_x[4*EBX], -1
	mov snake_y[4*EBX], -1
	jmp food_right
	
delete_food_r:
   inc scor
   make_snake food_x, food_y, 0555555h, direction
    pusha 
random_food_x_right:	
    rdtsc 
	xor EDX, EDX
	mov EBX, 500
	div EBX
	mov food_x, EDX
	cmp food_x, 10
	jl random_food_x_right
	
random_food_y_right:	
	xor EDX, EDX
	mov EBX, 500
	div EBX
	mov food_y, EDX
	cmp food_y, 10
	jl random_food_y_right
	
	push food_x
	push offset format_intreg
	call printf
	add ESP, 8
	
	push food_y
	push offset format_intreg
	call printf
	add ESP, 8
   ; make_snake food_x, food_y, 0f21838h, direction
	popa
food_right:
   mov EBX, 0
   make_snake snake_x[EBX], snake_y[EBX], 000ff83h, direction
draw_snake_right:
    inc EBX 
    cmp EBX, 20
	je continue
    cmp snake_x[EBX*4], -1
    je continue
	make_snake snake_x[4*EBX], snake_y[4*EBX],0ffffffh, direction
	cmp EBX, 20
	jl draw_snake_right
	jmp continue
	
;------------------DOWN-------------------------------	
down:
   add i, 16
   mov ECX, i
   add ECX, 7
   cmp ECX, area_height
   jl cont4
   mov i, 10
cont4:
   mov ECX, i
   mov snake_x[0], ECX
   mov ECX, j
   mov snake_y[0], ECX
   
   mov EBX, index
   add EBX, 2
;-----------------------------
   mov index_vector, 3
eti2:
   xor EDX, EDX
   xor EDI, EDI
   
   mov EDI, index_vector
   mov EDX, snake_x[4*EDI]
   cmp EDX, -1
   je eat_down
   
   mov contor, 16
repeta2:
   cmp snake_x[0], EDX
   je cmp_y_d
   dec EDX
   dec contor
   cmp contor, 0
jne repeta2
jmp inc_index_d
   
cmp_y_d:
   mov contor, 16
   xor EDX, EDX
   xor EDI, EDI
   mov EDI, index_vector
   mov EDX, snake_y[4*EDI]
d1:
   cmp snake_y[0], EDX
   je game_over_down
   dec EDX
   dec contor
   cmp contor, 0
jne d1

   mov contor, 16
   xor EDX, EDX
   xor EDI, EDI
   mov EDI, index_vector
   mov EDX, snake_y[4*EDI]
d2:
   cmp snake_y[0], EDX
   je game_over_down
   inc EDX
   dec contor
   cmp contor, 0
jne d2

inc_index_d:
   inc index_vector
   cmp index_vector, 18
   jl eti2
jmp eat_down
game_over_down:	
    xor EBX, EBX
	mov EBX, scor
    cmp EBX, high_score
    jl reset_score_d
	mov high_score, EBX
	

reset_score_d:	
    mov scor, 0
    
    xor EDX, EDX
	mov EDX, -1
delete_snake_down:
   inc EDX
   cmp snake_x[EDX*4], -1
   je delete_snake_down
   make_snake snake_x[4*EDX], snake_y[4*EDX], 0555555h, direction
   cmp EDX, 20
   jl delete_snake_down

    mov EDX, i_start
	mov i, EDX
	mov EDX, j_start
	mov j, EDX
	mov direction, 1
	
    mov snake_x[0], 20
	mov snake_y[0], 20
	xor EDX, EDX
	mov EDX, 1
delete_vector_down:
    mov snake_x[4*EDX], -1
	mov snake_y[4*EDX], -1
	inc EDX
	cmp EDX, 20
jne delete_vector_down
jmp continue

;-----------------------------

eat_down:    
   mov contor, 16
   xor EDX, EDX
   mov EDX, food_x
down0:
   cmp snake_x[0], EDX
   je cmp_y_down
   dec EDX
   dec contor
   cmp contor, 0
jne down0
jmp delete_last_d

cmp_y_down: 
   mov contor, 16
   xor EDX, EDX
   mov EDX, food_y
down1:
   cmp snake_y[0], EDX
   je delete_food_d
   dec EDX
   dec contor
   cmp contor, 0
jne down1

   mov contor, 16
   xor EDX, EDX
   mov EDX, food_y
down2:
   cmp snake_y[0], EDX
   je delete_food_u
   inc EDX
   dec contor
   cmp contor, 0
jne down2

delete_last_d:
   dec EBX
   cmp EBX, -1
   je delete_last_down
   mov EAX, snake_x[4*EBX]
   cmp EAX, -1
   je delete_last_d
delete_last_down:
   make_snake snake_x[4*EBX], snake_y[4*EBX], 0555555h, direction
   mov snake_x[4*EBX], -1
   mov snake_y[4*EBX], -1
   jmp food_down

delete_food_d:
   inc scor
   make_snake food_x, food_y, 0555555h, direction
    pusha 
random_food_x_down:	
    rdtsc 
	xor EDX, EDX
	mov EBX, 500
	div EBX
	mov food_x, EDX
	cmp food_x, 10
	jl random_food_x_down
	
random_food_y_down:	
	xor EDX, EDX
	mov EBX, 500
	div EBX
	mov food_y, EDX
	cmp food_y, 10
	jl random_food_y_down
	
	push food_x
	push offset format_intreg
	call printf
	add ESP, 8
	
	push food_y
	push offset format_intreg
	call printf
	add ESP, 8
    ;make_snake food_x, food_y, 0f21838h, direction
	popa
food_down:
   mov EBX, 0
   make_snake snake_x[EBX], snake_y[EBX], 000ff83h, direction
draw_snake_down:
   inc EBX
   cmp EBX, 20
   je continue
   cmp snake_x[EBX*4], -1
   je draw_snake_up
   make_snake snake_x[4*EBX], snake_y[4*EBX], 0ffffffh, direction
   cmp EBX, 20
   jl draw_snake_up
   jmp continue
;----------------------LEFT-----------------------------
left:
   sub j, 16
   mov ECX, j
   sub ECX, 7
   cmp ECX, 0
   jg cont3
   mov j, area_height-10
cont3:
   mov ECX, i
   mov snake_x[0], ECX
   mov ECX, j
   mov snake_y[0], ECX
   
   mov EBX, index
   add EBX, 2
;-------------------------------------------------------------
   mov index_vector, 3
eti3:
   xor EDX, EDX
   xor EDI, EDI
   
   mov EDI, index_vector
   mov EDX, snake_y[4*EDI]
   cmp EDX, -1
   je eat_left
   
   mov contor, 16
repeta3:
   cmp snake_y[0], EDX
   je cmp_x_l
   dec EDX
   dec contor
   cmp contor, 0
jne repeta3
jmp inc_index_l
   
cmp_x_l:
   mov contor, 16
   xor EDX, EDX
   xor EDI, EDI
   mov EDI, index_vector
   mov EDX, snake_x[4*EDI]
l1:
   cmp snake_x[0], EDX
   je game_over_left
   dec EDX
   dec contor
   cmp contor, 0
jne l1

   mov contor, 16
   xor EDX, EDX
   xor EDI, EDI
   mov EDI, index_vector
   mov EDX, snake_x[4*EDI]
l2:
   cmp snake_x[0], EDX
   je game_over_left
   inc EDX
   dec contor
   cmp contor, 0
jne l2

inc_index_l:
   inc index_vector
   cmp index_vector, 18
   jl eti3
jmp eat_left
game_over_left:	
    xor EBX, EBX
	mov EBX, scor
    cmp EBX, high_score
    jl reset_score_l
	mov high_score, EBX
	

reset_score_l:	
    mov scor, 0 
    
    xor EDX, EDX
	mov EDX, -1
delete_snake_left:
   inc EDX
   cmp snake_x[EDX*4], -1
   je delete_snake_left
   make_snake snake_x[4*EDX], snake_y[4*EDX], 0555555h, direction
   cmp EDX, 20
   jl delete_snake_left

    mov EDX, i_start
	mov i, EDX
	mov EDX, j_start
	mov j, EDX
	mov direction, 1
	
    mov snake_x[0], 20
	mov snake_y[0], 20
	xor EDX, EDX
	mov EDX, 1
delete_vector_left:
    mov snake_x[4*EDX], -1
	mov snake_y[4*EDX], -1
	inc EDX
	cmp EDX, 20
jne delete_vector_left
jmp continue


;-------------------------------------------------------------   
eat_left:
   mov contor, 16
   xor EDX, EDX
   mov EDX, food_y
left0:
   cmp snake_y[0], EDX
   je cmp_x_left
   dec EDX
   dec contor
   cmp contor, 0
jne left0
jmp delete_last_l

cmp_x_left: 
   mov contor, 16
   xor EDX, EDX
   mov EDX, food_x
left1:
   cmp snake_x[0], EDX
   je delete_food_l
   dec EDX
   dec contor
   cmp contor, 0
jne left1

   mov contor, 16
   xor EDX, EDX
   mov EDX, food_x
left2:
   cmp snake_x[0], EDX
   je delete_food_l
   inc EDX
   dec contor
   cmp contor, 0
jne left2

delete_last_l:
   dec EBX
   cmp EBX, -1
   je delete_last_left
   mov EAX, snake_x[4*EBX]
   cmp EAX, -1
   je delete_last_l
delete_last_left:
   make_snake snake_x[4*EBX], snake_y[4*EBX], 0555555h, direction
   mov snake_x[4*EBX], -1
   mov snake_y[4*EBX], -1
   jmp food_left

delete_food_l:
    inc scor  
    make_snake food_x, food_y, 0555555h, direction
    pusha 
random_food_x_left:	
    rdtsc 
	xor EDX, EDX
	mov EBX, 500
	div EBX
	mov food_x, EDX
	cmp food_x, 10
	jl random_food_x_left
	
random_food_y_left:	
	xor EDX, EDX
	mov EBX, 500
	div EBX
	mov food_y, EDX
	cmp food_y, 10
	jl random_food_y_left
	
	push food_x
	push offset format_intreg
	call printf
	add ESP, 8
	
	push food_y
	push offset format_intreg
	call printf
	add ESP, 8
   ; make_snake food_x, food_y, 0f21838h, direction
	popa
food_left:
   mov EBX, 0
   make_snake snake_x[EBX], snake_y[EBX], 000ff83h, direction
draw_snake_left:
   inc EBX
   cmp EBX, 20
   je continue
   cmp snake_x[EBX*4], -1
   je draw_snake_up
   make_snake snake_x[4*EBX], snake_y[4*EBX], 0ffffffh, direction
   cmp EBX, 20
   jl draw_snake_left
   jmp continue
   
;----------------------UP--------------------------------------
up:
   sub i, 16
   mov ECX, i
   sub ECX, 7
   cmp ECX, 0
   jg cont2
   mov i, area_height-10
cont2:
   mov ECX, i
   mov snake_x[0], ECX
   mov ECX, j
   mov snake_y[0], ECX
   
   mov EBX, index
   add EBX, 2
;---------------------------------------------------------------
  mov index_vector, 3
eti4:
   xor EDX, EDX
   xor EDI, EDI
   
   mov EDI, index_vector
   mov EDX, snake_x[4*EDI]
   cmp EDX, -1
   je eat_up
   
   mov contor, 16
repeta4:
   cmp snake_x[0], EDX
   je cmp_y_u
   dec EDX
   dec contor
   cmp contor, 0
jne repeta4
jmp inc_index_u
   
cmp_y_u:
   mov contor, 16
   xor EDX, EDX
   xor EDI, EDI
   mov EDI, index_vector
   mov EDX, snake_y[4*EDI]
u1:
   cmp snake_y[0], EDX
   je game_over_up
   dec EDX
   dec contor
   cmp contor, 0
jne u1

   mov contor, 16
   xor EDX, EDX
   xor EDI, EDI
   mov EDI, index_vector
   mov EDX, snake_y[4*EDI]
u2:
   cmp snake_y[0], EDX
   je game_over_up
   inc EDX
   dec contor
   cmp contor, 0
jne u2

inc_index_u:
   inc index_vector
   cmp index_vector, 18
   jl eti4
jmp eat_up
game_over_up:
    xor EBX, EBX
	mov EBX, scor
    cmp EBX, high_score
    jl reset_score_u
	mov high_score, EBX
	

reset_score_u:	
    mov scor, 0 
    
    xor EDX, EDX
	mov EDX, -1
delete_snake_up:
   inc EDX
   cmp snake_x[EDX*4], -1
   je delete_snake_up
   make_snake snake_x[4*EDX], snake_y[4*EDX], 0555555h, direction
   cmp EDX, 20
   jl delete_snake_up

    mov EDX, i_start
	mov i, EDX
	mov EDX, j_start
	mov j, EDX
	mov direction, 1
	
    mov snake_x[0], 20
	mov snake_y[0], 20
	xor EDX, EDX
	mov EDX, 1
delete_vector_up:
    mov snake_x[4*EDX], -1
	mov snake_y[4*EDX], -1
	inc EDX
	cmp EDX, 20
jne delete_vector_up
jmp continue

    
;---------------------------------------------------------------  
eat_up:
   mov contor, 16
   xor EDX, EDX
   mov EDX, food_x
up0:
   cmp snake_x[0], EDX
   je cmp_y_up
   inc EDX
   dec contor
   cmp contor, 0
jne up0
jmp delete_last_u

cmp_y_up: 
   mov contor, 16
   xor EDX, EDX
   mov EDX, food_y
up1:
   cmp snake_y[0], EDX
   je delete_food_u
   dec EDX
   dec contor
   cmp contor, 0
jne up1

   mov contor, 16
   xor EDX, EDX
   mov EDX, food_y
   
up2:
   cmp snake_y[0], EDX
   je delete_food_u
   inc EDX
   dec contor
   cmp contor, 0
jne up2

delete_last_u:
   dec EBX
   cmp EBX, -1
   je delete_last_up
   mov EAX, snake_x[4*EBX]
   cmp EAX, -1
   je delete_last_u
delete_last_up:
   make_snake snake_x[4*EBX], snake_y[4*EBX], 0555555h, direction
   mov snake_x[4*EBX], -1
   mov snake_y[4*EBX], -1
   jmp food_up

delete_food_u:
    inc scor
    make_snake food_x, food_y, 0555555h, direction
    pusha 
random_food_x_up:	
    rdtsc 
	xor EDX, EDX
	mov EBX, 500
	div EBX
	mov food_x, EDX
	cmp food_x, 10
	jl random_food_x_up

    
random_food_y_up:	
	xor EDX, EDX
	mov EBX, 500
	div EBX
	mov food_y, EDX
	cmp food_y, 10
	jl random_food_y_up
	
	push food_x
	push offset format_intreg
	call printf
	add ESP, 8
	
	push food_y
	push offset format_intreg
	call printf
	add ESP, 8
    ;make_snake food_x, food_y, 0f21838h, direction
	popa
food_up:
   mov EBX, 0
   make_snake snake_x[EBX], snake_y[EBX], 000ff83h, direction
draw_snake_up:
   inc EBX
   cmp EBX, 20
   je continue
   cmp snake_x[EBX*4], -1
   je draw_snake_up
   make_snake snake_x[4*EBX], snake_y[4*EBX], 0ffffffh, direction
   cmp EBX, 20
   jl draw_snake_up
   jmp continue
    	
continue:	
	xor EAX, EAX
	mov counter_sec, EAX
final_draw:
    ;make_lines 0, area_height-4, area_height
vertical_line 0, area_height-4, area_height, 000h
vertical_line 0, 0, area_height, 000h
horizontal_line 0, 0, area_height-2, 000h
horizontal_line area_height-3, 0, area_height-2, 000h



draw_button 268, 308, 580, 636, 56, 43, 000h ; up
draw_button 351, 391, 580, 636, 56, 43, 000h ; down 
draw_button 308, 351, 524, 580, 56, 43, 000h ; left
draw_button 308, 351, 636, 692, 59, 43, 000h ; right

oblical_line_left 278, 608,20, 000h
oblical_line_right 278, 608,20, 000h
horizontal_line1 298, 588, 40, 000h

horizontal_line1 361, 588, 40, 000h
oblical_line_right 361, 588, 20, 000h
oblical_line_left 361, 628, 21, 000h

vertical_line1 311, 560, 40, 000h
oblical_line_left 311, 560, 20, 000h
oblical_line_right 331, 540, 20, 00h

vertical_line1 311, 656, 40, 000h
oblical_line_right 311, 656, 20, 000h
oblical_line_left 331, 676, 20, 000h

	popa
	mov ESP, EBP
	pop EBP
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov EAX, area_width
	mov EBX, area_height
	mul EBX
	shl EAX, 2
	
	push EAX
	call malloc
	add ESP, 4
	
	mov area, EAX
	
	
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add ESP, 20
	
finish:
	;terminarea programului
	push 0
	call exit
end start
