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

section .rodata
    copyright_notice:
    db "Termo em assembly de x86_64  Copyright (C) 2025  filipemd", 10
    db "This program comes with ABSOLUTELY NO WARRANTY; for details see the LICENSE file.", 10
    db "This is free software, and you are welcome to redistribute it", 10
    db "under certain conditions; see the LICENSE file for details.", 10, 10, 0

    copyright_notice_size: equ $-copyright_notice

section .text

display_copyright:
    ; sys_write(unsigned int fd, char *buf, size_t count)
    mov rax, 1
    mov rdi, 1
    mov rsi, copyright_notice
    mov rdx, copyright_notice_size
    syscall

    ret

global display_copyright