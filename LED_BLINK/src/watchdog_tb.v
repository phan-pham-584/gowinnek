// watchdog_tb.v
module watchdog_tb();
    reg clk, rst_n;
    reg btn_s1, btn_s2;
    wire led_d3, led_d4;
    
    watchdog_top uut (
        .clk_50m(clk),
        .rst_n(rst_n),
        .btn_s1(btn_s1),
        .btn_s2(btn_s2),
        .led_d3(led_d3),
        .led_d4(led_d4),
        .uart_rx(1'b1),
        .uart_tx()
    );
    
    always #10 clk = ~clk;  // 50MHz
    
    initial begin
        clk = 0;
        rst_n = 0;
        btn_s1 = 1;
        btn_s2 = 1;
        #100 rst_n = 1;
        
        // Test: Enable watchdog
        #100 btn_s2 = 0;  // EN = 1
        #100 btn_s2 = 1;
        
        // Test: Kick WDI
        #5000 btn_s1 = 0;
        #20 btn_s1 = 1;
        
        // Test: Wait for timeout (~1600ms simulated)
        #200000000;  // Simulate timeout
        
        $finish;
    end
endmodule