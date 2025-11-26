`timescale 1ns / 1ps

//some parameters are changed for simulation purposes

module car_control_FSM (
    input clk,          // 100MHz system clock
    input BTNL,         // Left button (active high)
    input BTNR,         // Right button (active high)
    input BTNC,         // Center button (Restart/Reset)
    input [7:0] random_num,
    output reg [9:0] rival_x_reg,
    output reg [9:0] rival_y_reg,
    output reg rival_active,
    output reg [9:0] car_x_reg, // Car X position (read/write)
    output reg [9:0] car_y_reg, // Car Y position (read/write)
    output [2:0] current_state_out,
    output wire collided        // Collision indicator
);

    // --- FSM State Definitions ---
    localparam [2:0]
        START     = 3'b000,
        IDLE      = 3'b001,
        LEFT_CAR  = 3'b010,
        RIGHT_CAR = 3'b011,
        COLLIDE   = 3'b100;

    reg [2:0] current_state, next_state;

    // --- Car and Boundary Constants ---
    // The problem defines the car position starts at (270, 300)
    localparam START_CAR_X = 270;
    localparam START_CAR_Y = 300;
    // Car width is 14 pixels (from Display_sprite.v)
    localparam main_car_width = 14;
    localparam main_car_height = 16;
    // Road Boundaries (based on X=244 and X=318)
    localparam LEFT_BOUNDARY = 244;
    localparam RIGHT_BOUNDARY = 318;

    // Rival Car Constants
    localparam rival_car_width = 14;
    localparam rival_car_height = 16;
    localparam RIVAL_START_Y = 150 - rival_car_height + 12 ; // OFFSET_BG_Y
    localparam RIVAL_END_Y = 390;   // OFFSET_BG_Y + bg1_height
    localparam MIN_RIVAL_X = 244;   // LEFT_BOUNDARY
    localparam MAX_RIVAL_X = 304;   // RIGHT_BOUNDARY - rival_car_width

    // Collision Wires - Check only when rival is active
    wire collide_left = (car_x_reg < LEFT_BOUNDARY);
    wire collide_right = (car_x_reg + main_car_width > RIGHT_BOUNDARY);

    // Rival car collision detection - only check if rival is active
    wire collide_with_rival =(car_x_reg < rival_x_reg + rival_car_width) &&
                            (car_x_reg + main_car_width > rival_x_reg) &&
                            (car_y_reg < rival_y_reg + rival_car_height) &&
                            (car_y_reg + main_car_height > rival_y_reg);

    // Rival car vertical movement divider (slower than main car)
    localparam RIVAL_MOVE_FRAMES = 20'd1000000; // Adjust for desired speed
    reg [19:0] rival_move_count = 0;
    wire rival_move_en = (rival_move_count == RIVAL_MOVE_FRAMES - 1);

    always @ (posedge clk) begin
        if (rival_move_count == RIVAL_MOVE_FRAMES - 1)
            rival_move_count <= 0;
        else
            rival_move_count <= rival_move_count + 1;
    end

    // --- Slow Clock Enable for Movement (Divider) ---
    // Divide 100MHz by 4,000,000 (25 times per second) for visible movement (only for simulation purposes)
    localparam CLK_DIV_CYCLES = 20'd4000000;
    reg [19:0] move_count = 0;
    wire move_clk_en = (move_count == CLK_DIV_CYCLES - 1);

    assign current_state_out = current_state;
    assign collided = (current_state == COLLIDE);

    always @ (posedge clk) begin
        if (move_count == CLK_DIV_CYCLES - 1)
            move_count <= 0;
        else
            move_count <= move_count + 1;
    end

    // --- 1. State Register (Sequential) ---
    always @ (posedge clk) begin
        if (BTNC) // BTNC acts as a master reset/restart
            current_state <= START;
        else
            current_state <= next_state;
    end

    // --- 2. Next State Logic (Combinational) ---
    always @ (*) begin
        next_state = current_state; // Default: Stay in current state

        case (current_state)
            START: begin
                // Go to IDLE unconditionally
                next_state = IDLE;


            end

            IDLE: begin
                if (collide_with_rival)
                    next_state = COLLIDE;
                else if (BTNR)
                    next_state = RIGHT_CAR;
                else if (BTNL)
                    next_state = LEFT_CAR;
            end

            RIGHT_CAR: begin
                if (collide_right || collide_with_rival)
                    next_state = COLLIDE; // Collision check
                else if (!BTNR)
                    next_state = IDLE;    // Button released
            end

            LEFT_CAR: begin
                if (collide_left || collide_with_rival)
                    next_state = COLLIDE; // Collision check
                else if (!BTNL)
                    next_state = IDLE;    // Button released
            end

            COLLIDE: begin
                // Stay here until the center button is pressed to restart
                if (BTNC)
                    next_state = START;
            end

            default: next_state = START;
        endcase
    end

    // --- Rival Car Position Update ---
    always @ (posedge clk) begin
        if (BTNC || current_state == START) begin
            // Initialize rival car at random position at top
            rival_x_reg <= MIN_RIVAL_X + (random_num % (MAX_RIVAL_X - MIN_RIVAL_X + 1));
            rival_y_reg <= RIVAL_START_Y;
            rival_active <= 1;
        end
//        else if (current_state == COLLIDE) begin
//            // Stop rival car movement on collision
//            rival_active <= 0;
//        end
        else if (!collided && rival_move_en) begin
            if (rival_y_reg >= RIVAL_END_Y - rival_car_height) begin
                // Rival reached bottom, respawn at top
                rival_x_reg <= MIN_RIVAL_X + (random_num % (MAX_RIVAL_X - MIN_RIVAL_X + 1));
                rival_y_reg <= RIVAL_START_Y;
                rival_active <= 1;
            end
            else begin
                // Move rival car down
                rival_y_reg <= rival_y_reg + 2; // Move 2 pixels down
            end
        end
    end

    // --- 3. Car Position Update (Sequential) ---
    // Initialize and update Y position
    always @ (posedge clk) begin
        if (BTNC || current_state == START) begin
            car_y_reg <= START_CAR_Y; // Initialize Y position
        end
        // Car Y stays constant during the game (no vertical movement)
    end

    // Update X position with movement
    always @ (posedge clk) begin
        if (BTNC || current_state == START) begin
            car_x_reg <= START_CAR_X; // Reset position


        end
        else if (move_clk_en && current_state != COLLIDE) begin
            case (current_state)
                RIGHT_CAR: begin
                    // Move right by 1 pixel
                    car_x_reg <= car_x_reg + 1;
                end
                LEFT_CAR: begin
                    // Move left by 1 pixel
                    car_x_reg <= car_x_reg - 1;
                end
                // IDLE state doesn't change car_x
                default: car_x_reg <= car_x_reg;
            endcase
        end
    end

endmodule