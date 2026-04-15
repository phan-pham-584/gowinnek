// watchdog_core.sv
// Watchdog FSM - Mealy machine
// 4 states: DISABLED, ARM, ACTIVE, FAULT

module watchdog_core (
    input  wire clk,
    input  wire rst_n,
    
    // Điều khiển từ regfile
    input  wire en,                 // Enable watchdog (từ CTRL bit0)
    input  wire clr_fault,          // Clear fault (từ CTRL bit2)
    
    // Kick events
    input  wire kick_event,         // Từ debounce S1 hoặc UART KICK
    
    // Timer inputs (từ timer modules)
    input  wire arm_delay_done,     // Hết arm_delay
    input  wire wd_timer_expired,   // Hết tWD
    input  wire rst_timer_expired,  // Hết tRST
    
    // Timer control outputs (điều khiển timer)
    output reg  start_timer_arm,    // Bắt đầu đếm arm_delay (xung)
    output reg  reset_timer_wd,     // Reset timer WD (xung)
    output reg  enable_timer_wd,    // Cho phép timer WD chạy (level)
    output reg  reset_timer_rst,    // Reset timer RST (xung)
    output reg  enable_timer_rst,   // Cho phép timer RST chạy (level)
    
    // Watchdog outputs
    output reg  wdo,                // Watchdog output (active low)
    output reg  enout               // Enable out (1 = system allowed)
);

    // State encoding (3 bit)
    localparam [2:0]
        DISABLED = 3'b000,
        ARM      = 3'b001,
        ACTIVE   = 3'b010,
        FAULT    = 3'b011;
    
    reg [2:0] state, next_state;
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= DISABLED;
        else
            state <= next_state;
    end
    
    // Next state and output logic (Mealy)
    always @(*) begin
        // Default outputs
        next_state = state;
        wdo = 1'b1;
        enout = 1'b0;
        start_timer_arm = 1'b0;
        reset_timer_wd = 1'b0;
        enable_timer_wd = 1'b0;
        reset_timer_rst = 1'b0;
        enable_timer_rst = 1'b0;
        
        case (state)
            DISABLED: begin
                wdo = 1'b1;
                enout = 1'b0;
                if (en) begin
                    next_state = ARM;
                    start_timer_arm = 1'b1;
                end
            end
            
            ARM: begin
                wdo = 1'b1;
                enout = 1'b0;
                if (!en) begin
                    next_state = DISABLED;
                end else if (arm_delay_done) begin
                    next_state = ACTIVE;
                    reset_timer_wd = 1'b1;
                    enable_timer_wd = 1'b1;
                    enout = 1'b1;
                end
            end
            
            ACTIVE: begin
                wdo = 1'b1;
                enout = 1'b1;
                enable_timer_wd = 1'b1;
                
                if (!en) begin
                    next_state = DISABLED;
                    enout = 1'b0;
                    enable_timer_wd = 1'b0;
                end else if (wd_timer_expired) begin
                    next_state = FAULT;
                    wdo = 1'b0;
                    enout = 1'b0;
                    enable_timer_wd = 1'b0;
                    reset_timer_rst = 1'b1;
                    enable_timer_rst = 1'b1;
                end else if (kick_event) begin
                    next_state = ACTIVE;
                    reset_timer_wd = 1'b1;
                end
            end
            
            FAULT: begin
                wdo = 1'b0;
                enout = 1'b0;
                enable_timer_rst = 1'b1;
                
                if (!en) begin
                    next_state = DISABLED;
                    wdo = 1'b1;
                    enable_timer_rst = 1'b0;
                end else if (clr_fault || rst_timer_expired) begin
                    next_state = ACTIVE;
                    wdo = 1'b1;
                    enout = 1'b1;
                    enable_timer_rst = 1'b0;
                    reset_timer_wd = 1'b1;
                    enable_timer_wd = 1'b1;
                end
            end
            
            default: begin
                next_state = DISABLED;
                wdo = 1'b1;
                enout = 1'b0;
            end
        endcase
    end

endmodule