; =============================================================================
; COAL Final Project: Brick Breaker Game 
; Authors: Ahmed Sahi & Imtinan ul Haq

; =============================================================================

org 100h

section .data
    ; Display Characters
    bar_symbol      db  223
    sphere_symbol   db  'O'
    block_symbol    db  219
    
    ; Colors
    bar_color       db  0x3A
    sphere_color    db  0x0F
    
    ; Paddle Configuration
    bar_col         dw  35
    bar_row         dw  23
    bar_size        dw  10
    
    ; Ball State
    sphere_col      dw  40
    sphere_row      dw  20
    sphere_h_speed  dw  0
    sphere_v_speed  dw  -1
    
    ; Screen Boundaries
    max_columns     dw  80
    max_rows        dw  25
    
    ; Game Statistics
    player_score    dw  0
    remaining_lives dw  3
    blocks_left     dw  0
    
    ; Brick state array (16 bricks per row * 4 rows = 64 bricks)
    brick_states    times 64 db 1
    bricks_per_row  dw  16
    
    ; Score values per row
    row_points      dw  40, 30, 20, 10  ; Blue, Cyan, Yellow, Red
    
    ; Messages
    msg_welcome     db 13,10
                    db '******************************************',13,10
                    db '*                                        *',13,10
                    db '*       A T A R I   B R E A K O U T      *',13,10
                    db '*                                        *',13,10
                    db '*    Presented by Ahmed Sahi &&          *',13,10
                    db '*               Imtinan ul Haq           *',13,10
                    db '*                                        *',13,10
                    db '******************************************',13,10
                    db 13,10
                    db ' > Use < > to control the paddle        ',13,10
                    db ' > Ball bounces 90 degrees from center! ',13,10
                    db ' > 4-cell bricks with gaps!             ',13,10
                    db 13,10
                    db ' Brick Values:',13,10
                    db '   BLUE = 40 pts | CYAN = 30 pts',13,10
                    db '   YELLOW = 20 pts | RED = 10 pts',13,10
                    db 13,10
                    db ' [ENTER] - BEGIN DESTRUCTION            ',13,10
                    db ' [ESC]   - ABORT MISSION                ',13,10
                    db 13,10,'$'
    
    msg_defeat      db  'MISSION FAILED! Your Score: $'
    msg_victory     db  'VICTORY! All Bricks Destroyed! Score: $'
    msg_points      db  'Points: $'
    msg_life        db  ' Lives: $'
    msg_exit_only   db  '[ESC] - ABORT MISSION', '$'
    line_break      db  13, 10, '$'

section .text
    global _start

_start:
    mov ax, 0003h
    int 10h
    
    mov ah, 01h
    mov ch, 20h
    int 10h

display_intro:
    call erase_display
    
    mov dh, 2
    mov dl, 0
    call position_cursor
    
    mov dx, msg_welcome
    mov ah, 09h
    int 21h
    
await_input:
    mov ah, 00h
    int 16h
    
    cmp al, 13
    je near setup_game
    cmp al, 27
    je near terminate_program
    jmp await_input

setup_game:
    call erase_display
    
    mov word [player_score], 0
    mov word [remaining_lives], 3
    mov word [bar_col], 35
    mov word [sphere_col], 40
    mov word [sphere_row], 20
    mov word [sphere_h_speed], 0
    mov word [sphere_v_speed], -1
    mov word [blocks_left], 0
    
    ; Reset brick states
    mov cx, 64
    mov di, brick_states
reset_bricks:
    mov byte [di], 1
    inc di
    loop reset_bricks
    
    call render_blocks
    call render_bar
    call show_stats
    
    call pause_frame

main_cycle:
    ; Keyboard handling
    mov ah, 01h
    int 16h
    jz no_key_pressed
    
    mov ah, 00h
    int 16h
    
    cmp al, 27
    je near terminate_program
    
    cmp ah, 4Bh
    je shift_left
    cmp ah, 4Dh
    je shift_right
    
no_key_pressed:
    ; Clear keyboard buffer
    mov ah, 01h
    int 16h
    jz skip_key
    mov ah, 00h
    int 16h
    jmp no_key_pressed

shift_left:
    cmp word [bar_col], 0
    jle no_key_pressed
    
    call erase_bar
    
    sub word [bar_col], 2
    cmp word [bar_col], 0
    jge no_key_pressed
    mov word [bar_col], 0
    jmp no_key_pressed

shift_right:
    mov ax, [bar_col]
    add ax, [bar_size]
    cmp ax, [max_columns]
    jge no_key_pressed
    
    call erase_bar
    
    add word [bar_col], 2
    
    mov ax, [bar_col]
    add ax, [bar_size]
    cmp ax, [max_columns]
    jle no_key_pressed
    mov ax, [max_columns]
    sub ax, [bar_size]
    mov [bar_col], ax
    jmp no_key_pressed
    
skip_key:
    call pause_frame
    
    ; Erase old ball position
    mov dh, byte [sphere_row]
    mov dl, byte [sphere_col]
    mov bl, 0
    mov al, ' '
    call place_character
    
    call update_sphere
    
    ; ALWAYS render paddle every frame to prevent disappearing cells
    call render_bar
    call render_sphere
    call show_stats
    
    cmp word [remaining_lives], 0
    je near display_defeat
    
    cmp word [blocks_left], 0
    je near display_victory
    
    jmp main_cycle

; =============================================================================
; Movement & Physics
; =============================================================================

update_sphere:
    ; Move ball
    mov ax, [sphere_col]
    add ax, [sphere_h_speed]
    mov [sphere_col], ax
    
    mov ax, [sphere_row]
    add ax, [sphere_v_speed]
    mov [sphere_row], ax
    
    ; Check LEFT wall
    cmp word [sphere_col], 0
    jg check_right_wall
    mov word [sphere_col], 0
    neg word [sphere_h_speed]
    call audio_bounce

check_right_wall:
    cmp word [sphere_col], 79
    jl check_ceiling
    mov word [sphere_col], 79
    neg word [sphere_h_speed]
    call audio_bounce

check_ceiling:
    cmp word [sphere_row], 0
    jg check_floor
    mov word [sphere_row], 0
    neg word [sphere_v_speed]
    call audio_bounce

check_floor:
    mov ax, [max_rows]
    dec ax
    cmp [sphere_row], ax
    jl check_bar_collision
    
    ; Ball fell
    dec word [remaining_lives]
    call audio_loss
    
    mov word [sphere_col], 40
    mov word [sphere_row], 20
    mov word [sphere_v_speed], -1
    mov word [sphere_h_speed], 0
    ret

check_bar_collision:
    ; Enhanced paddle collision
    mov ax, [sphere_row]
    cmp ax, [bar_row]
    jne check_brick_collision
    
    mov ax, [sphere_col]
    cmp ax, [bar_col]
    jl check_brick_collision
    
    mov bx, [bar_col]
    add bx, [bar_size]
    cmp ax, bx
    jg check_brick_collision
    
    ; Calculate hit position for angle
    mov ax, [sphere_col]
    sub ax, [bar_col]
    
    mov bx, [bar_size]
    mov dx, 0
    mov cx, 3
    div cx
    
    cmp ax, 0
    je hit_left_third
    cmp ax, 1
    je hit_center_third
    
    mov word [sphere_h_speed], 2
    jmp bounce_up

hit_left_third:
    mov word [sphere_h_speed], -2
    jmp bounce_up

hit_center_third:
    mov word [sphere_h_speed], 0

bounce_up:
    mov word [sphere_v_speed], -1
    call audio_bounce
    ret

check_brick_collision:
    ; Check if ball is in brick area (rows 2-5)
    mov al, byte [sphere_row]
    cmp al, 2
    jl near no_brick_hit
    cmp al, 5
    jg near no_brick_hit
    
    ; Calculate which brick was hit
    mov al, byte [sphere_col]
    xor ah, ah
    mov bl, 5
    div bl
    
    cmp ah, 4
    je near no_brick_hit
    
    ; Validate brick number is in range (0-15)
    cmp al, 16
    jge near no_brick_hit
    
    ; Calculate brick ID
    mov bl, al
    mov al, byte [sphere_row]
    sub al, 2
    mov cl, 4
    shl al, cl
    add al, bl
    
    ; Validate brick ID is in range (0-63)
    cmp al, 64
    jge near no_brick_hit
    
    ; Check if brick is active
    xor bh, bh
    mov bl, al
    cmp byte [brick_states + bx], 0
    je near no_brick_hit
    
    ; Destroy brick
    mov byte [brick_states + bx], 0
    dec word [blocks_left]
    
    call audio_brick
    
    ; Award points based on row (0=Blue=40, 1=Cyan=30, 2=Yellow=20, 3=Red=10)
    mov al, byte [sphere_row]
    sub al, 2               ; AL = 0, 1, 2, or 3
    xor ah, ah
    mov si, ax
    shl si, 1               ; SI = row * 2 (word offset)
    mov ax, [row_points + si]
    add word [player_score], ax
    
    ; Erase brick (4 cells)
    mov al, byte [sphere_col]
    xor ah, ah
    mov bl, 5
    div bl
    mov bl, 5
    mul bl
    mov dl, al
    
    mov dh, byte [sphere_row]
    mov cx, 4

clear_brick_loop:
    push cx
    push dx
    mov al, ' '
    mov bl, 0
    call place_character
    pop dx
    inc dl
    pop cx
    loop clear_brick_loop
    
    neg word [sphere_v_speed]

no_brick_hit:
    ret

; =============================================================================
; Rendering Functions
; =============================================================================

render_blocks:
    ; Render 4 rows filling entire width (80 columns)
    ; Pattern: [BBBB]_[BBBB]_[BBBB]_... (4 cells brick + 1 gap)
    mov dh, 2
    mov cx, 4

next_brick_row:
    push cx
    
    ; Set color based on row (Blue, Cyan, Yellow, Red)
    cmp dh, 2
    je set_blue
    cmp dh, 3
    je set_cyan
    cmp dh, 4
    je set_yellow
    mov bl, 0x0C                ; Red
    jmp start_brick_columns

set_blue:
    mov bl, 0x09                ; Blue
    jmp start_brick_columns

set_cyan:
    mov bl, 0x0B                ; Cyan
    jmp start_brick_columns

set_yellow:
    mov bl, 0x0E                ; Yellow
    
start_brick_columns:
    mov dl, 0                   ; Start from column 0
    push bx

fill_entire_row:
    ; Check if we have space for at least 4 cells
    mov al, dl
    add al, 4
    cmp al, 80
    jg row_complete             ; If we can't fit 4 cells, row is done
    
    ; Draw 4 cells for this brick
    push dx
    mov cx, 4
draw_brick_cell:
    push cx
    mov al, [block_symbol]
    call place_character
    inc dl
    pop cx
    loop draw_brick_cell
    pop dx
    
    inc word [blocks_left]
    
    ; Move to next brick position (4 cells + 1 gap = 5)
    add dl, 5
    
    ; Check if we reached or exceeded column 80
    cmp dl, 80
    jl fill_entire_row
    
row_complete:
    pop bx
    inc dh
    pop cx
    loop next_brick_row
    ret

render_bar:
    mov dh, byte [bar_row]
    mov dl, byte [bar_col]
    mov cx, [bar_size]
    mov bl, [bar_color]
    mov al, [bar_symbol]

bar_draw_loop:
    call place_character
    inc dl
    loop bar_draw_loop
    ret

erase_bar:
    mov dh, byte [bar_row]
    mov dl, byte [bar_col]
    mov cx, [bar_size]
    mov bl, 0
    mov al, ' '

bar_erase_loop:
    call place_character
    inc dl
    loop bar_erase_loop
    ret

render_sphere:
    mov dh, byte [sphere_row]
    mov dl, byte [sphere_col]
    mov bl, [sphere_color]
    mov al, [sphere_symbol]
    call place_character
    ret

show_stats:
    push ax
    push bx
    push cx
    push dx
    
    ; Clear entire status line first to prevent overlap
    mov dh, 0
    mov dl, 0
    call position_cursor
    
    mov cx, 80
    mov al, ' '
    mov bl, 0x07
clear_status_line:
    push cx
    call place_character
    inc dl
    pop cx
    loop clear_status_line
    
    ; Display "Points: XXXXX"
    mov dh, 0
    mov dl, 0
    call position_cursor
    mov dx, msg_points
    mov ah, 09h
    int 21h
    
    mov ax, [player_score]
    call display_number
    
    ; Display "Lives: X"
    mov dh, 0
    mov dl, 60
    call position_cursor
    mov dx, msg_life
    mov ah, 09h
    int 21h
    
    mov ax, [remaining_lives]
    call display_number
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =============================================================================
; Utility Functions
; =============================================================================

position_cursor:
    mov ah, 02h
    mov bh, 00h
    int 10h
    ret

place_character:
    push ax
    push bx
    push cx
    push dx
    
    call position_cursor
    
    mov ah, 09h
    mov bh, 00h
    mov cx, 1
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

erase_display:
    mov ah, 06h
    mov al, 0
    mov bh, 07h
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 10h
    ret

pause_frame:
    mov ah, 00h
    int 1Ah
    mov bx, dx
    add bx, 2

frame_wait:
    int 1Ah
    cmp dx, bx
    jl frame_wait
    ret

audio_bounce:
    mov bx, 1000
    jmp create_sound

audio_brick:
    mov bx, 2000
    jmp create_sound

audio_loss:
    mov bx, 500

create_sound:
    mov al, 182
    out 43h, al
    mov ax, bx
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h
    or al, 03h
    out 61h, al
    
    mov cx, 0200h

sound_wait:
    loop sound_wait
    
    in al, 61h
    and al, 0FCh
    out 61h, al
    ret

display_number:
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0
    mov bx, 10

    test ax, ax
    jnz number_loop
    mov al, '0'
    mov ah, 0Eh
    int 10h
    jmp number_complete

number_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz number_loop

number_output:
    pop ax
    add al, '0'
    mov ah, 0Eh
    int 10h
    loop number_output

number_complete:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

display_defeat:
    call erase_display
    
    mov dh, 10
    mov dl, 20
    call position_cursor
    mov dx, msg_defeat
    mov ah, 09h
    int 21h
    
    mov ax, [player_score]
    call display_number
    
    mov dh, 12
    mov dl, 25
    call position_cursor
    
    mov dx, msg_exit_only
    mov ah, 09h
    int 21h
    
    jmp await_exit

display_victory:
    call erase_display
    
    mov dh, 10
    mov dl, 10
    call position_cursor
    mov dx, msg_victory
    mov ah, 09h
    int 21h
    
    mov ax, [player_score]
    call display_number
    
    mov dh, 12
    mov dl, 25
    call position_cursor
    
    mov dx, msg_exit_only
    mov ah, 09h
    int 21h

await_exit:
    mov ah, 00h
    int 16h
    
    cmp al, 27
    je terminate_program
    
    jmp await_exit

terminate_program:
    mov ax, 0003h
    int 10h
    
    mov ax, 4C00h
    int 21h