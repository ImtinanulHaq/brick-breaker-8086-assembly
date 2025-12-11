🎮 Brick Breaker – 8086 Assembly (COAL Final Project)

A fully functional Atari-style Brick Breaker Game built entirely in 8086 Assembly Language as the COAL Final Project.
This project implements real-time gameplay, physics-based movement, keyboard input handling, score management, lives system, sound effects, and text-mode graphics using BIOS interrupts.

📌 Features
🕹 Gameplay Mechanics

Smooth paddle movement using keyboard arrow keys (← and →)

Real-time ball physics with horizontal & vertical velocity

Dynamic collision detection:

Paddle collision (with angle-based reflection)

Brick collision (with scoring)

Wall & ceiling bounce

Lives system (3 lives)

Game over (Defeat) & All bricks destroyed (Victory) screens

🧱 Brick System

4 rows of bricks:

Blue – 40 pts

Cyan – 30 pts

Yellow – 20 pts

Red – 10 pts

64 bricks total (4 rows × 16 bricks)

Brick destruction & scoring logic

🔊 Sound Effects

Paddle/wall bounce sound

Brick hit sound

Life lost sound
(All using PIT speaker control)

💻 Graphics & Rendering

Text-mode rendering using BIOS interrupts

Paddle, ball, and multi-color bricks drawn character-by-character

Efficient screen updates

Score & lives displayed on a status bar

📁 Project Structure
Project.asm         # Complete Assembly source code
README.md           # Project documentation

🛠 Technologies Used

8086 Assembly Language

Real-mode x86 architecture

BIOS interrupts

INT 10h → Video Services

INT 21h → DOS Services

INT 16h → Keyboard Input

INT 1Ah → Delay/Timer


👥 Authors

Ahmed Sahi

Imtinan ul Haq

📜 License

This project is released for educational purposes under the MIT License.
