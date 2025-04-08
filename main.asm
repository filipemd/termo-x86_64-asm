; Termo em assembly de x86_64
; Copyright (C) 2025  filipemd
;
; This file is part of Termo em assembly de x86_64.
;
; Termo em assembly de x86_64 is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Termo em assembly de x86_64 is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Termo em assembly de x86_64.  If not, see <https://www.gnu.org/licenses/>.


%define WORD_SIZE 5
%define WORD_AMOUNT 100

section .rodata
    initial_text:  
        db 'Bem vindo ao termo! Você vai ter que adivinhar uma palavra de 5 letras. Ela não vai ter acento, então, por exemplo, a palavra "porém" vai ficar "porem".', 10
        db 'Quando você dar o palpite de uma palavra, o jogo vai te dar dicas de onde cada letra está na palavra correta:', 10
        db '_ = a letra não está na palavra - 0 = a letra está na palavra, mas não nessa posição - <letra correta> = a letra está nessa exata posição', 10
        db 'Por exemplo, vamos supor que a palavra correta é "MANGA" e o jogador deu o palpite de "PLENA", o jogo vai mostrar para o jogador:', 10
        db '___0A', 10
        db 'Porque N faz parte de MANGA, só que não na mesma posição de PLENA, e A faz parte de MANGA na mesma posição de PLENA', 10, 10
        db 'Você terá seis tentativas. Boa sorte!', 10, 0

    initial_text_size: equ $-initial_text

    guess_word_text: db 'Seu palpite de palavra (5 letras apenas): ', 0
    guess_word_text_size: equ $-guess_word_text

    guess_right_text: db 'Acertou a palavra!', 10, 0
    guess_right_text_size: equ $-guess_right_text

    game_over_text: db 'Você perdeu!', 10, 0
    game_over_text_size: equ $-game_over_text

    O: db '0'
    _: db '_'
    linebreak: db 10

    extern words

section .data
    tries: db 6 ; Seis tentativas

section .bss
    random_number: resb 1
    word_to_guess: resq 1 ; Armazena 64-bits de data para ser um ponteiro para a palavra para adivinhar
    input_word: resb WORD_SIZE

section .text
    global _start
    extern display_copyright

_start:
    ; Mostra o aviso de copyright
    call display_copyright

    ; Mostra o texto inicial
    ; sys_write(unsigned int fd, char *buf, size_t count)
    mov rax, 1
    mov rdi, 1
    mov rsi, initial_text
    mov rdx, initial_text_size
    syscall

    ; sys_getrandom(char __user *buf, size_t count, unsigned int flags)
    mov rax, 318
    mov rdi, random_number ; Armazena o número aleatório no registrador RSP
    mov rsi, 1
    mov rdx, 0 ; Nenhuma flag
    syscall  

    ; Para debug apenas
     mov byte [random_number], 0

    ; O número está entre 0-255, mas ele tem que estar entre 0-<WORD_AMOUNT>
    mov al, byte [random_number] ; Coloca o número aleatório em AL
    mov bl, WORD_AMOUNT ; Coloca 100 em BL
    xor edx, edx ; Limpa o EDX, para fazer a divisão
    div bl ; Faz a divisão
    mov [random_number], ah

    ; Agora, é necessário pegar uma palavra aleatória da lista. Como todas as
    ; palavras têm cinco letras e (importante), todas estão em ASCII, eu posso
    ; multiplicar o índice por cinco e somar com a posição das palavras da
    ; memória e, pronto, vou ter um ponteiro para ela
    movzx rdi, byte [random_number] ; Converte o valor de AL para o de RDI. RDI é 64-bit enquanto AL é 8-bit
    imul rdi, rdi, 5 ; Multiplica RDI com 5
    mov rsi, words ; O registrador RSI aponta para `words`
    add rsi, rdi ; Soma RSI com RDI para, finalmente, RSI ser um ponteiro para a palavra aleatória
    mov [word_to_guess], rsi ; `word_to_guess` é um ponteiro para a palavra aleatória

.loop:
    ; Mostra o texto pedindo o palpite
    ; sys_write(unsigned int fd, const char *buf, size_t count)
    mov rax, 1
    mov rdi, 1
    mov rsi, guess_word_text
    mov rdx, guess_word_text_size
    syscall

    ; Armazena o palpite que o usuário deu (equivalente a scanf() em C)
    ; sys_read(unsigned int fd, char *buf, size_t count)
    mov rax, 0
    mov rdi, 1
    mov rsi, input_word
    mov rdx, WORD_SIZE+1 ; Tem que contar o '/0'
    syscall

    ; Converte a entrada do usuário para letras maiúsculas
    ; string_toupper(char* string, size_t size)
    mov rdi, input_word
    mov rsi, WORD_SIZE
    call string_toupper

    ; Vê se a resposta está correta
    ; strings_equal(const char* string1, const char* string2, size_t string_size)
    mov rdi, input_word
    mov rsi, [word_to_guess]
    mov rdx, WORD_SIZE
    call strings_equal

    cmp al, 1 ; Se as strings forem iguais...
    je .guess_right ; Pula para `guess_right`

    ; print_string_similarities(const char* guess, const char* word, size_t string_size)
    mov rdi, input_word
    mov rsi, [word_to_guess]
    mov rdx, WORD_SIZE
    call print_string_similarities

    dec byte [tries]

    mov al, [tries]
    cmp al, 0

    jg .loop ; Loop infinito

.game_over:
    ; Mostra que o jogador perdeu o jogo
    ; sys_write(unsigned int fd, char *buf, size_t count)
    mov rax, 1
    mov rdi, 1
    mov rsi, game_over_text
    mov rdx, game_over_text_size
    syscall
    
    jmp .end

.guess_right:
    ; Mostra que o palpite estava certo
    ; sys_write(unsigned int fd, char *buf, size_t count)
    mov rax, 1
    mov rdi, 1
    mov rsi, guess_right_text
    mov rdx, guess_right_text_size
    syscall

.end: 
    ; sys_exit(int error_code)
    mov rax, 60
    xor rdi, rdi
    syscall

; Argumentos:
;   rdi - string 1
;   rsi - string 2
;   rdx - tamanho das strings
; Retorna:
;   al - 1 se as strings forem iguais, 0 se não forem
strings_equal:
.compare_loop:
    mov al, byte [rdi]
    mov bl, byte [rsi]

    ; Se não forem iguais, vai para `not_equal`
    cmp al, bl
    jne .not_equal

    ; Itera no loop
    inc rdi
    inc rsi

    dec rdx ; Loop reverso, RDX começa com o tamanho da string e cai com o tempo
    jnz .compare_loop ; Se não for igual a zero, roda o loop de novo

    ; Retorna um
    mov al, 1
    ret

.not_equal:
    mov al, 0 ; Retorna 0
    ret

; Argumentos:
;   rdi - string
;   rsi - tamanho da string
string_toupper:
    xor rdx, rdx ; Zera o contador de caracteres
.loop:
    cmp rdx, rsi ; Vê se o contador está igual ao tamanho da string (ou seja, o loop chegou ao fim)
    jge .done ; Se for, termina a função

    ; Como RDI é a string e RDX é o contador, a posição de um caracter específico na string é RDI+RDX
    mov al, byte [rdi+rdx]

    ; Verifica se o caractere é uma letra minúscula
    cmp al, 'a'
    jl .next ; Se a letra for menor que 'a', não é uma letra minúscula
    cmp al, 'z'
    jg .next ; Se a letra for maior que 'z', não é uma letra minúscula

    sub al, 32 ; Subtraindo uma letra minúscula por 32, se converte ela para maiúscula
    mov byte [rdi + rdx], al ; Armazena a nova letra na string

.next:
    inc rdx
    jmp .loop

.done:
    ret

; Argumentos:
;   rdi - palpite do jogador
;   rsi - string para adivinhar
;   rdx - tamanho das strings
print_string_similarities:
    ; sys_write utiliza registradores que seriam utilizados na função. Por isso, vários valores
    ; serão copiados
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx

    xor r15, r15 ; Coloca o contador como sendo zero

.loop:
    cmp r15, r14 ; Se chegamos no fim do loop
    jge .end ; Vai para o fim da função

    ; Itera sobre o array e coloca cada caracter nos registradores AL e BL
    mov al, byte [r12 + r15]
    mov bl, byte [r13 + r15]

    ; Se os caracteres forem iguais, imprime o caracter X
    cmp al, bl
    je .print_X

    ; Vê se a letra está na palavra
    xor r9, r9 ; R9 vai ser o contador do loop, por isso ele é igual a zero

.search_loop:
    cmp byte[r13+r9], al ; Vê se o valor do caracter no loop é igual a palavra
    je .print_0

    inc r9
    cmp r9, r14 ; Vê se o loop chegou ao fim
    jl .search_loop ; Se não chegou, roda o loop de novo

    jmp .print_ ; Se, em todo o loop, não foi encontrada a letra, mostra um underline

; Se chama assim por motivos históricos
.print_X:
    sub rsp, 1 ; Reserva 1 byte de espaço na stack
    mov byte [rsp], al ; Coloca o valor de AL (a letra em que a posição foi acertada)

    ; sys_write(unsigned int fd, char *buf, size_t count)
    mov rax, 1
    mov rdi, 1
    mov rsi, rsp ; Imprime o caracter
    mov rdx, 1
    syscall

    add rsp, 1 ; Limpa a stack
    jmp .next

.print_0:
    ; sys_write(unsigned int fd, char *buf, size_t count)
    mov rax, 1
    mov rdi, 1
    mov rsi, O
    mov rdx, 1
    syscall
    jmp .next

.print_:
    ; sys_write(unsigned int fd, char *buf, size_t count)
    mov rax, 1
    mov rdi, 1
    mov rsi, _
    mov rdx, 1
    syscall
    jmp .next

.next:
    inc r15
    jmp .loop

.end:
    ; Mostra quebra de linha
    ; sys_write(unsigned int fd, char *buf, size_t count)
    mov rax, 1
    mov rdi, 1
    mov rsi, linebreak
    mov rdx, 1
    syscall
    ret