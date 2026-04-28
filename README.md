# FPGA Based Smart Pomodoro Timer ⏱️

## 📌 Overview

This project implements a **hardware-based Pomodoro Timer** using Verilog on FPGA (Basys 3 board).
Unlike software timers, it eliminates distractions by providing a **dedicated physical device** for focused study sessions.

Supported modes:

* Classic: **25 min work / 5 min break**
* Deep Work: **52 min work / 17 min break**

---

## 🎯 Objectives

* Accurately manage work and break sessions
* Enable **automatic session transitions**
* Display remaining time in **MM:SS format**
* Track:

  * Distractions during work sessions
  * Completed Pomodoro cycles
* Provide a **minimal, distraction-free interface**

---

## 🛠️ Hardware & Tools

* **FPGA Board:** Digilent Basys 3 (Artix-7)
* **HDL:** Verilog
* **Design Tool:** Xilinx Vivado
* **Clock Frequency:** 100 MHz

---

## ⚙️ Key Features

* ⏱️ Real-time countdown timer
* 🔄 Automatic work ↔ break switching
* 📊 Distraction counter (during work phase)
* 📈 Pomodoro session counter
* ⚡ Demo mode (60× faster execution for testing)
* 🔁 Stats mode (display counters instead of time)
* 💡 LED-based status visualization

---

## 🎮 Inputs & Controls

| Input   | Function                      |
| ------- | ----------------------------- |
| `btnC`  | Play / Pause                  |
| `btnL`  | Reset                         |
| `sw[1]` | Demo mode (fast timing)       |
| `sw[2]` | Method select (25/5 or 52/17) |
| `sw[3]` | Toggle stats display          |

---

## 🧠 System Architecture

The system is implemented using a **Finite State Machine (FSM)** with four states:

* `IDLE`
* `RUNNING`
* `PAUSED`
* `DONE`

### Responsibilities of FSM:

* Timer control
* State transitions
* Counter updates

---

## 🔄 System Workflow

```
IDLE → RUNNING → PAUSED ↔ RUNNING → DONE → NEXT SESSION
```

* `btnC` starts/pauses execution
* Timer expiration triggers `DONE`
* System automatically switches between work and break
* Long break is triggered after 4 work sessions

---

## 🧩 Core Modules

* Clock Divider (1 Hz tick generator)
* Debounce Logic (button stabilization)
* FSM Controller
* Timer Module
* 7-Segment Display Driver
* LED Status Controller

---

## 📺 Output System

### 7-Segment Display

* Displays time in **MM:SS**
* Blinking colon indicates **RUNNING state**

### LED Panel

* Work / Break / Running / Paused status
* Distraction count (binary)
* Pomodoro count (binary)

---

## ⚠️ Challenges & Solutions

| Problem              | Solution                           |
| -------------------- | ---------------------------------- |
| Button bouncing      | Implemented debounce logic         |
| FSM instability      | Used structured state-based design |
| Display misalignment | Corrected anode mapping            |
| Timing inconsistency | Fixed clock/tick synchronization   |

---

## 🚧 Limitations

* Fixed session durations (requires recompilation)
* No persistent storage
* Limited user interface
* Single-user operation

---

## 🚀 Future Improvements

* Configurable timer durations
* Non-volatile memory (EEPROM/Flash)
* Audio alerts (buzzer integration)
* LCD/OLED display upgrade
* Real-time clock (RTC) integration

---

## 📂 Project Structure

```
.
├── pomodorovthree.v        # Main Verilog module
├── pomodorovthree.xdc      # Constraint file
├── Pomodoro_Project_Report.pdf
├── README.md
```

---

## 🧑‍💻 Authors

* MD. Farhan Hossain
* Nabeel Sarwar Tahmeed

---

## 📖 Conclusion

This project demonstrates a practical application of FPGA in building a **distraction-free productivity tool**.
It effectively integrates FSM-based control logic, timing mechanisms, and hardware interfaces into a complete system.

---
