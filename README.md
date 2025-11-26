#  FPGA Car Racing Game (Basys-3)

A minimal car-racing game implemented on the **Basys-3** FPGA board.  
Features include VGA output, player movement, rival car spawning using an LFSR, and bounding-box collision detection.

---

## Project Structure

```
fpga-car-racing/
│
├── src/
│   ├── Vert_counter.v
│   ├── Horiz_counter.v
│   ├── clk_divider.v
│   ├── VGA_driver.v
│   ├── car_control.v
│   ├── LFSR_8bit.v
│   ├── Display_sprite-7.v
│   └── basys3-9.xdc
│   └── new_tb.v
│
└── README.md
```


### `clk_divider.v`  
Converts the 100 MHz Basys-3 clock into a 25 MHz VGA pixel clock.

### `VGA_driver.v`  
Generates VGA sync signals and pixel coordinates for a 640×480 display.

### `car_control.v`  
Controls player movement (left/right), rival car movement, random X-spawning, and collision detection + freeze.

### `LFSR_8bit.v`  
8-bit Linear Feedback Shift Register used to generate pseudo-random rival positions.

### `Display_sprite-7.v`  
Renders the road, player car, and rival car as colored rectangles on screen.

### `basys3-9.xdc`  
Basys-3 pin mapping for VGA, clock, and push buttons.

---

## How to Run
1. Import all `.v` files into a Vivado project.
2. Load the `basys3-9.xdc` file with your Basys-3 VGA & button pin mappings.
3. Generate the bitstream and program the board.
4. Control the car:
   - **BTNL** → Left  
   - **BTNC** → Reset/game restart  
   - **BTNR** → Right  

---

## Features
- 640×480 VGA output at 60 Hz  
- Player movement inside road boundaries  
- Rival car falling from random positions  
- Simple collision detection  
- Freeze screen on collision until reset  

---

