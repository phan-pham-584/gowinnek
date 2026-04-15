// regfile.sv
// Register map cho watchdog
// Địa chỉ: 0x00=CTRL, 0x04=tWD_ms, 0x08=tRST_ms, 0x0C=arm_delay_us

module regfile (
    input  wire clk,
    input  wire rst_n,
    
    // Giao tiếp từ UART parser
    input  wire reg_wr_en,          // 1 = ghi register
    input  wire [7:0] reg_addr,     // Địa chỉ (byte)
    input  wire [31:0] reg_wr_data, // Dữ liệu ghi
    output reg  [31:0] reg_rd_data, // Dữ liệu đọc
    
    // Outputs cho watchdog core và timers
    output reg  en,                  // Enable watchdog (CTRL bit0)
    output reg  clr_fault,          // Clear fault (CTRL bit2, write-1-to-clear)
    output reg  [31:0] twd_ms,      // Watchdog timeout (ms)
    output reg  [31:0] trst_ms,     // WDO hold time (ms)
    output reg  [15:0] arm_delay_us // Arm delay (us)
);

    // Register addresses
    localparam ADDR_CTRL         = 8'h00;
    localparam ADDR_TWD_MS       = 8'h04;
    localparam ADDR_TRST_MS      = 8'h08;
    localparam ADDR_ARM_DELAY_US = 8'h0C;
    
    // Register storage
    reg [31:0] ctrl_reg;        // bit0=EN, bit1=WDI_SRC, bit2=CLR_FAULT
    reg [31:0] twd_ms_reg;
    reg [31:0] trst_ms_reg;
    reg [15:0] arm_delay_us_reg;
    
    // Default values after reset
    localparam DEFAULT_CTRL         = 32'd0;           // disabled
    localparam DEFAULT_TWD_MS       = 32'd1600;        // 1600 ms
    localparam DEFAULT_TRST_MS      = 32'd200;         // 200 ms
    localparam DEFAULT_ARM_DELAY_US = 16'd150;         // 150 us
    
    //------------------------------------------------
    // Write registers
    //------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg         <= DEFAULT_CTRL;
            twd_ms_reg       <= DEFAULT_TWD_MS;
            trst_ms_reg      <= DEFAULT_TRST_MS;
            arm_delay_us_reg <= DEFAULT_ARM_DELAY_US;
        end else if (reg_wr_en) begin
            case (reg_addr)
                ADDR_CTRL:         ctrl_reg         <= reg_wr_data;
                ADDR_TWD_MS:       twd_ms_reg       <= reg_wr_data;
                ADDR_TRST_MS:      trst_ms_reg      <= reg_wr_data;
                ADDR_ARM_DELAY_US: arm_delay_us_reg <= reg_wr_data[15:0];
                default: ;  // ignore
            endcase
        end else begin
            // Clear CLR_FAULT bit sau 1 chu kỳ (write-1-to-clear)
            if (ctrl_reg[2])
                ctrl_reg[2] <= 1'b0;
        end
    end
    
    //------------------------------------------------
    // Read registers
    //------------------------------------------------
    always @(*) begin
        case (reg_addr)
            ADDR_CTRL:         reg_rd_data = ctrl_reg;
            ADDR_TWD_MS:       reg_rd_data = twd_ms_reg;
            ADDR_TRST_MS:      reg_rd_data = trst_ms_reg;
            ADDR_ARM_DELAY_US: reg_rd_data = {16'd0, arm_delay_us_reg};
            default:           reg_rd_data = 32'd0;
        endcase
    end
    
    //------------------------------------------------
    // Output assignments
    //------------------------------------------------
    always @(*) begin
        en = ctrl_reg[0];
        // clr_fault là xung (đọc rồi tự xóa ở trên)
        clr_fault = ctrl_reg[2];
        twd_ms = twd_ms_reg;
        trst_ms = trst_ms_reg;
        arm_delay_us = arm_delay_us_reg;
    end

endmodule