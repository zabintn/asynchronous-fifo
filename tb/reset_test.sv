`timescale 1ns/1ps
module tb_top;

    localparam DATA_WIDTH = 32;
    localparam FIFO_DEPTH = 16;

    logic wr_clk;
    logic w_arst_n;
    logic wr_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic full;

    logic rd_clk;
    logic r_arst_n;
    logic rd_en;
    logic [DATA_WIDTH-1:0] rd_data;
    logic empty;

    int errors = 0;

    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) dut (
        .wr_clk(wr_clk), .w_arst_n(w_arst_n), .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rd_clk(rd_clk), .r_arst_n(r_arst_n), .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
    );

    always #5   wr_clk = ~wr_clk;  

    always #5   rd_clk = ~rd_clk;  
   
    initial begin
	    $dumpfile("Waveform.vcd");
	    $dumpvars(0, tb_top);
    end

    initial begin
	    wr_clk=0;
	    rd_clk=0;
	    wr_en = 0;
	    wr_data = '0;
	    rd_en = 0;
	    w_arst_n = 0;
	    r_arst_n = 0;

        // RESET ASSERTION AT THE BEGINNING
        
	repeat (3) @(posedge wr_clk);
        w_arst_n = 1;
        r_arst_n = 1;

	#1;


	if (full !== 1'b0)  begin 
		$error("[T1] full expected 0, got %0b", full); 
		errors++; 
	end
	if (empty !== 1'b1) begin 
		$error("[T1] empty expected 1, got %0b", empty); 
		errors++; 
	end
	if (rd_data !== '0) begin 
		$error("[T1] rd_data expected 0, got %0h", rd_data); 
		errors++; 
	end


       
        // RESET ASSERTED MID FIFO OPERATION
	for (int i = 0; i < 5; i++) begin
		@(posedge wr_clk);
		wr_en=1;
		wr_data=$urandom;
	end
		wr_en=0;
	repeat (4) @(posedge rd_clk);
        	rd_en=1;
	repeat (2) @(posedge rd_clk);
		rd_en=0;
	
        if (empty !== 1'b0) begin
            $error("expected empty=0 mid-operation, got 1");
            errors++;
        end

        #3.3;
        w_arst_n = 0;
        r_arst_n = 0;
        #4;         
       	if (full !== 1'b0 || empty !== 1'b1) begin
            $error("[flags did not reset: full=%0b empty=%0b", full, empty);
            errors++;
        end
        repeat (3) @(posedge wr_clk);
        repeat (3) @(posedge rd_clk);
        w_arst_n = 1;
        r_arst_n = 1;
        wr_en = 0;
        rd_en = 0;

	if (full !== 1'b0)  begin 
		$error("[T1] full expected 0, got %0b", full); 
		errors++; 
	end
	if (empty !== 1'b1) begin 
		$error("[T1] empty expected 1, got %0b", empty); 
		errors++; 
	end
	if (rd_data !== '0) begin 
		$error("[T1] rd_data expected 0, got %0h", rd_data); 
		errors++; 
	end


        // write domain reset
	for (int i = 0; i < 4; i++) begin
		@(posedge wr_clk);
		wr_en=1;
		wr_data=$urandom;
	end
        wr_en=0;
       	repeat (4) @(posedge wr_clk)
        w_arst_n = 0;
        repeat (3) @(posedge wr_clk);
        w_arst_n = 1;
        @(posedge wr_clk);
        if (dut.u_wptr_handler.wptr_bin !== '0) begin
            $error("Write pointer did not clear on write-only reset");
            errors++;
        end

        //read domain reset
        for (int i = 0; i < 4; i++) begin
                @(posedge wr_clk);
                wr_en=1;
                wr_data=$urandom;
        end
	@(posedge rd_clk);
	rd_en=1;
       	r_arst_n = 0;
        repeat (3) @(posedge rd_clk);
        r_arst_n = 1;
        @(posedge rd_clk);
        if (dut.u_rptr_handler.rptr_bin !== '0) begin
            $error("[T5] read pointer did not clear on read-only reset");
            errors++;
        end
end

    // safety timeout
    initial begin
        #500;
        $finish;
    end

endmodule
