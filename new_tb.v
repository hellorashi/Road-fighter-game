`timescale 1ns / 1ps

module Display_sprite_tb;

    reg clk;
    reg BTNL, BTNR, BTNC;
    wire HS, VS;
    wire [11:0] vgaRGB;
    
    wire [9:0] car_x, car_y;
    wire [9:0] rival_x, rival_y;
    wire rival_active;
    wire [7:0] random_num;
    wire [2:0] current_state;
    wire collided;
    
    integer collision_time;
    reg collision_detected;
    
    reg [9:0] collision_car_x, collision_car_y;
    reg [9:0] collision_rival_x, collision_rival_y;

    Display_sprite #(
        .pixel_counter_width(10),
        .OFFSET_BG_X(200),
        .OFFSET_BG_Y(150)
    ) uut (
        .clk(clk),
        .BTNL(BTNL),
        .BTNR(BTNR),
        .BTNC(BTNC),
        .HS(HS),
        .VS(VS),
        .vgaRGB(vgaRGB)
    );
    
    assign car_x = uut.car_x;
    assign car_y = uut.car_y;
    assign rival_x = uut.rival_x;
    assign rival_y = uut.rival_y;
    assign rival_active = uut.rival_active;
    assign random_num = uut.random_num;
    assign current_state = uut.current_game_state;
    assign collided = (current_state == 3'b100);
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        BTNL = 0;
        BTNR = 0;
        BTNC = 0;
        collision_time = 0;
        collision_detected = 0;
        
        BTNC = 1;
        #100;
        BTNC = 0;
        #100;
        
        repeat(10) begin
            #1000;
        end
        
        #50000;
        
        if (car_x < rival_x) begin
            BTNR = 1;
            #200000;
            BTNR = 0;
        end else if (car_x > rival_x) begin
            BTNL = 1;
            #200000;
            BTNL = 0;
        end
        
        #800000;
        
        if (collided) begin
            collision_detected = 1;
            collision_time = $time;
            
            collision_car_x = car_x;
            collision_car_y = car_y;
            collision_rival_x = rival_x;
            collision_rival_y = rival_y;
        end
        
        BTNR = 1;
        #10000;
        BTNR = 0;
        #1000;
        
        #20000;
        
        BTNC = 1;
        #100;
        BTNC = 0;
        #1000;
        
        $finish;
    end
    
    reg [2:0] prev_state;
    initial prev_state = 0;
    
    always @(posedge clk) begin
        if (current_state != prev_state) begin
            prev_state = current_state;
        end
    end
    
    initial begin
        #2000000;
        $finish;
    end

endmodule
