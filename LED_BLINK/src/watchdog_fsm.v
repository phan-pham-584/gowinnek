// watchdog_fsm.v
module watchdog_fsm (
    input  wire clk,
    input  wire rst_n,
    // Control signals from regfile
    input  wire en_sw,              // EN_SW bit0
    input  wire clr_fault,          // CLR_FAULT bit2
    // Status from datapath
    input  wire arm_expired,
    input  wire twd_expired,
    input  wire trst_expired,
    input  wire wdi_falling,
    // Control outputs to datapath
    output reg  arm_load,
    output reg  arm_en,
    output reg  arm_clr,
    output reg  twd_load,
    output reg  twd_en,
    output reg  twd_clr,
    output reg  twd_reload,         // Reset on kick
    output reg  trst_load,
    output reg  trst_en,
    output reg  trst_clr,
    output reg  wdi_en,
    // Outputs
    output reg  wdo,                // Active-low fault output
    output reg  enout               // Enabled indicator
);
    // FSM states
    localparam STATE_DISABLED   = 3'd0;
    localparam STATE_ARMING     = 3'd1;
    localparam STATE_ACTIVE     = 3'd2;
    localparam STATE_FAULT      = 3'd3;
    localparam STATE_FAULT_WAIT = 3'd4;
    
    reg [2:0] state, next_state;
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= STATE_DISABLED;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            STATE_DISABLED:
                if (en_sw)
                    next_state = STATE_ARMING;
                    
            STATE_ARMING:
                if (!en_sw)
                    next_state = STATE_DISABLED;
                else if (arm_expired)
                    next_state = STATE_ACTIVE;
                    
            STATE_ACTIVE:
                if (!en_sw)
                    next_state = STATE_DISABLED;
                else if (twd_expired)
                    next_state = STATE_FAULT;
                    
            STATE_FAULT:
                if (!en_sw)
                    next_state = STATE_DISABLED;
                else if (trst_expired || clr_fault)
                    next_state = STATE_FAULT_WAIT;
                    
            STATE_FAULT_WAIT:
                if (!en_sw)
                    next_state = STATE_DISABLED;
                else
                    next_state = STATE_ACTIVE;
                    
            default: next_state = STATE_DISABLED;
        endcase
    end
    
    // Output logic (Moore)
    always @(*) begin
        // Default values
        arm_load = 0;
        arm_en = 0;
        arm_clr = 0;
        twd_load = 0;
        twd_en = 0;
        twd_clr = 0;
        twd_reload = 0;
        trst_load = 0;
        trst_en = 0;
        trst_clr = 0;
        wdi_en = 0;
        wdo = 1;      // Inactive high (open-drain = Hi-Z)
        enout = 0;
        
        case (state)
            STATE_DISABLED:
                begin
                    arm_clr = 1;
                    twd_clr = 1;
                    trst_clr = 1;
                    wdi_en = 0;
                end
                
            STATE_ARMING:
                begin
                    arm_load = 1;
                    arm_en = 1;
                    wdi_en = 0;
                end
                
            STATE_ACTIVE:
                begin
                    twd_load = 1;
                    twd_en = 1;
                    wdi_en = 1;
                    enout = 1;
                    
                    if (wdi_falling)
                        twd_reload = 1;
                end
                
            STATE_FAULT:
                begin
                    trst_load = 1;
                    trst_en = 1;
                    wdi_en = 1;
                    enout = 1;
                    wdo = 0;      // Assert fault low
                end
                
            STATE_FAULT_WAIT:
                begin
                    wdi_en = 1;
                    enout = 1;
                end
        endcase
    end
endmodule