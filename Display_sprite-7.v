`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Delhi
// Engineer: Naman Jain
// 
// Create Date: 09/24/2025 07:45:32 PM
// Design Name: 
// Module Name: Display_sprite
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Display_sprite #(
        // Size of signal to store  horizontal and vertical pixel coordinate
        parameter pixel_counter_width = 10,
        parameter OFFSET_BG_X = 200,
        parameter OFFSET_BG_Y = 150 
    )
    (
        input clk,
        input BTNL,BTNR, BTNC,
        output HS, VS,
        output [11:0] vgaRGB
    );
    
    localparam bg1_width = 160;
    localparam bg1_height = 240;
    
    localparam main_car_width = 14;
    localparam main_car_height = 16;
    
    localparam COLLIDE = 3'b100;

    localparam rival_car_width = 14;
    localparam rival_car_height = 16;

    // Rival car signals
    wire [9:0] rival_x_fsm;
    wire [9:0] rival_y_fsm;
    wire rival_active_fsm;
    wire [7:0] random_num;
    reg [9:0] rival_x;
    reg [9:0] rival_y;
    reg rival_active;
    reg [7:0] rival_rom_addr;
    wire [11:0] rival_color;
    reg rival_on;
    
    wire [2:0] current_game_state;
    wire pixel_clock;
    wire [3:0] vgaRed, vgaGreen, vgaBlue;
    wire [pixel_counter_width-1:0] hor_pix, ver_pix;
    reg [11:0] output_color;
    reg [11:0] next_color;
    reg [15:0] bg_rom_addr;
    wire [11:0] bg_color;
    reg [7:0] car_rom_addr;
    wire [11:0] car_color;
    reg [9:0] bg_offset_y = 0;
    reg bg_on, car_on;
    reg [pixel_counter_width-1:0] car_x;
    wire [pixel_counter_width-1:0] car_x_fsm;
    reg [pixel_counter_width-1:0] car_y = 300;
    
    //Main display driver 
    VGA_driver #(
        .WIDTH(pixel_counter_width)
    )   display_driver (
        //DO NOT CHANGE, clock from basys 3 board
        .clk(clk),
        .vgaRed(vgaRed), .vgaGreen(vgaGreen), .vgaBlue(vgaBlue),
        //DO NOT CHANGE, VGA signal to basys 3 board
        .HS(HS),
        .VS(VS),
        .vgaRGB(vgaRGB),
        //Output pixel clocks
        .pixel_clock(pixel_clock),
        //Horizontal and Vertical pixel coordinates
        .hor_pix(hor_pix),
        .ver_pix(ver_pix)
    );

    rival_car_rom rival_rom (
    .clka(clk),
    .addra(rival_rom_addr),
    .douta(rival_color)
    );
    
    LFSR_8bit #(
        .SEED(8'b00010011)
    ) random_gen (
        .clk(clk),
        .rst(BTNC),
        .random_out(random_num)
    );
    bg_rom bg1_rom (
        .clka(clk),
        .addra(bg_rom_addr),
        .douta(bg_color)
    );
    
    main_car_rom car1_rom (
        .clka(clk),
        .addra(car_rom_addr),
        .douta(car_color)
    );

    car_control_FSM car_fsm(
        .clk(clk),
        .BTNL(BTNL),
        .BTNR(BTNR),
        .BTNC(BTNC),
        .car_x_reg(car_x_fsm),
        .rival_x_reg(rival_x_fsm),
        .rival_y_reg(rival_y_fsm),
        .rival_active(rival_active_fsm),
        .random_num(random_num),
        .current_state_out(current_game_state)
    );
    
    localparam BG_CLK_DIV_CYCLES = 20'd500000;
    reg [19:0] bg_move_count = 0;
    wire bg_move_en = (bg_move_count == BG_CLK_DIV_CYCLES -1);
    
    always@(posedge clk) begin 
        if(bg_move_count == BG_CLK_DIV_CYCLES -1)
            bg_move_count  <=0;
        else
            bg_move_count <= bg_move_count +1;
    end    
    
    
   always@ (posedge clk) begin
    if(bg_move_en) begin
        if(current_game_state != COLLIDE) begin
            if(bg_offset_y == 1)
                bg_offset_y <= bg1_height -1;
            
            else 
                bg_offset_y <= bg_offset_y - 1;
             
        end 
  end
  end  
  
                  
//    assign car_x = 270;
//    assign car_y = 300;
    always@(posedge clk) begin
        car_x <= car_x_fsm;
    end

    always@(posedge clk) begin
        rival_x <= rival_x_fsm;
        rival_y <= rival_y_fsm;
        rival_active <= rival_active_fsm;
    end

    always @ (posedge clk) begin : CAR_LOCATION
        if (hor_pix >= car_x && hor_pix < (car_x + main_car_width) && ver_pix >= car_y && ver_pix < (car_y + main_car_height)) begin
            car_rom_addr <= (hor_pix - car_x) + (ver_pix - car_y)*main_car_width;
            car_on <= 1;
        end
        else begin
            car_on <= 0;
        end
    end

    always @ (posedge clk) begin : RIVAL_CAR_LOCATION
    if ( hor_pix >= rival_x && hor_pix < (rival_x + rival_car_width) &&
        ver_pix >= rival_y && ver_pix < (rival_y + rival_car_height)) begin
        rival_rom_addr <= (hor_pix - rival_x) + (ver_pix - rival_y) * rival_car_width;
        rival_on <= 1;
    end
    else begin
        rival_on <= 0;
    end
end

//    reg [pixel_counter_width -1:0] bg_pix_y;
//    reg [pixel_counter_width-1:0] shifted_bg_pix_y;

    always @ (posedge clk) begin : BG_LOCATION
        if (hor_pix >= 0 + OFFSET_BG_X && hor_pix < bg1_width + OFFSET_BG_X && ver_pix >= 0 + OFFSET_BG_Y && ver_pix < bg1_height + OFFSET_BG_Y) begin
        
            
//            bg_pix_y <= ver_pix - OFFSET_BG_Y ;
            
            
//            shifted_bg_pix_y <= (bg_pix_y + bg_offset_y) % bg1_height; 
        
        
            bg_rom_addr <= (hor_pix - OFFSET_BG_X) + ((ver_pix - OFFSET_BG_Y + bg_offset_y) % bg1_height)*bg1_width;
            bg_on <= 1;
        end
        else
            bg_on <= 0;
    end
    
    always @ (posedge clk) begin : MUX_VGA_OUTPUT
        if (car_on && car_color!=12'b101000001010) begin
                next_color <= car_color;
            end
        else if(rival_on && rival_color != 12'b101000001010) begin
                next_color <= rival_color;
            end
        else if (bg_on) begin
            next_color <= bg_color;
        end
        else
            next_color <= 0;
    end

    always @ (posedge pixel_clock) begin
        output_color <= next_color;
    end
    
    assign vgaRed = output_color[11:8];
    assign vgaGreen = output_color[7:4];
    assign vgaBlue = output_color[3:0];
    
    
endmodule