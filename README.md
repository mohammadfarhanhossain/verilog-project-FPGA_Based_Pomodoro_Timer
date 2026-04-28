# FPGA Based Smart Pomodoro Timer ⏱️

## 📌 Overview

This project implements a **hardware-based Pomodoro Timer** using Verilog on FPGA (Basys 3 board).
It eliminates distractions from smartphones by providing a dedicated physical timer for focused study sessions.

The system follows:

* Classic **25 min work / 5 min break**
* Alternative **52 min work / 17 min break**

---

## 🎯 Objectives

* Track work and break sessions accurately
* Implement automatic transitions between sessions
* Display time in **MM:SS format on 7-segment display**
* Count:

  * Distractions
  * Completed Pomodoro cycles
* Provide a minimal and distraction-free interface

---

## 🛠️ Hardware & Tools

* FPGA Board: Digilent Basys 3 (Artix-7)
* HDL: Verilog
* Software: Xilinx Vivado
* Clock: 100 MHz

---

## ⚙️ Features

* ⏱️ Real-time countdown timer
* 🔄 Automatic work ↔ break switching
* 📊 Distraction counter
* 📈 Pomodoro session counter
* ⚡ Demo mode (60× faster simulation)
* 🔁 Stats mode (display counters instead of time)
* 💡 LED status indicators

---

## 🎮 Inputs & Controls

* `btnC` → Play / Pause
* `btnL` → Reset
* `sw[1]` → Demo mode
* `sw[2]` → Method select (25/5 or 52/17)
* `sw[3]` → Stats display toggle

---

## 🧠 System Architecture

The system is built using a **Finite State Machine (FSM)** with 4 states:

* `IDLE`
* `RUNNING`
* `PAUSED`
* `DONE`

According to the report, the FSM controls:

* Timer decrement
* Session transitions
* Counter updates 

---

## 🔄 Workflow

The system flow is shown in the diagram (report page 11):

* Start → IDLE
* btnC → RUNNING
* Timer ends → DONE
* Auto transition → Break / Work
* Repeat cycle

👉 The flowchart on page 11 clearly shows:

* Session switching
* Long break logic
* Counter updates 

---

## 🧩 Key Modules

* Clock Divider (1 Hz tick generator)
* Debounce Logic (button stability)
* FSM Controller
* Timer Counter
* 7-Segment Display Controller
* LED Status Panel

---

## 📺 Output System

* **7-Segment Display**

  * Shows time (MM:SS)
  * Blinking colon indicates RUNNING state

* **LED Panel**

  * Work/Break status
  * Distraction count
  * Pomodoro count

---

## ⚠️ Challenges Faced

* Button bouncing → fixed using debounce logic
* Incorrect FSM transitions → fixed via state-based design
* Display issues → corrected anode mapping
* Timing bugs → synchronized tick logic 

---

## 🚧 Limitations

* Fixed durations (requires recompilation)
* No persistent storage
* Limited UI (no display for settings)
* Single-user system 

---

## 🚀 Future Improvements

* Adjustable timer settings
* EEPROM/Flash integration
* Buzzer/audio alerts
* LCD/OLED display
* Real-time clock integration 

---

## 📂 Files

* `pomodorovthree.v` → Main Verilog module
* `pomodorovthree.xdc` → Constraints file
* `Pomodoro_Project_Report.pdf` → Full documentation

---

## 🧑‍💻 Authors

* MD. Farhan Hossain
* Nabeel Sarwar Tahmeed

---

## 📖 Conclusion

This project demonstrates how FPGA can be used to build a **practical productivity tool** using hardware-level design.
It successfully integrates FSM, timing logic, and user interaction into a complete system.

---
