`timescale 1ns/1ps

module tb_top;

 	parameter DATA_WIDTH=32; 
	parameter FIFO_DEPTH=16;

	logic wr_clk;
	logic w_arst_n;
	logic wr_en;
	logic [DATA_WIDTH-1:0] wr_data;
	
	logic rd_clk;
	logic r_arst_n;
	logic rd_en;
	logic [DATA_WIDTH-1:0] rd_data;

	logic full;
	logic empty;

	int error_count;
	int read_count;
	int write_count;


	//clock generation
	//write clock, 10ns
	
	always #7 wr_clk=~wr_clk;
	
	//read clock, 16ns
	
	always #5 rd_clk=~rd_clk;

	//module instantiation
	//
	
	async_fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) DUT (
		.wr_clk(wr_clk), .w_arst_n(w_arst_n), .wr_en(wr_en), .wr_data(wr_data), .full(full),
		.rd_clk(rd_clk), .r_arst_n(r_arst_n), .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
		);
	
	//dump data for waveform
	
	initial begin
		$dumpfile("Waveform.vcd");
		$dumpvars(0, tb_top);
	end
	
	//reset test
	
	initial begin
		$display("[%0t] RESET ASSERTED", $time);
		wr_clk=0;
		rd_clk=0;
		w_arst_n=0;
		r_arst_n=0;
		rd_en=0;
		wr_en=0;

		#20;
		
		w_arst_n=1;
		r_arst_n=1;
		$display("[%0t] RESET DEASSERTED", $time);
		
		if (full!==0) begin
                        $display("ERROR SHOULD BE EMPTY AFTER RESET");
                        error_count++;
                end
		
                if (empty!=1 || rd_data!==0) begin
                        $display("EMPTY SHOULD BE 1/READ DATA SHOULD BE 0 AFTER RESET");
                        error_count++;
                end

                if (error_count==0) begin
                        $display("[%0t] RESET TEST PASSED", $time);
                end
                else
                        $display("[%0t] RESET TEST FAILED",$time);

			
	end
	//write cases
	
	initial begin
	      	@(posedge w_arst_n);
		for (int i = 0; i < 4; i++) begin
		       	@(posedge wr_clk);
			if (!full) begin
				
				wr_en=1;
				wr_data=$urandom;
				$display("[%0t] WRITING DATA= %0h", $time, wr_data);
				write_count++;
				@(posedge rd_clk);
				wr_en=0;
			end
			else begin
				wr_en=0;
				$display("[%0t] FIFO FULL!", $time);
			end
		end
		wr_en=0;
		$display("WRITE PROCESS COMPLETE. TOTAL WRITE COUNT= %0d", write_count);
	end


	//read cases
	
	initial begin
    	@(posedge r_arst_n);
    	wait(wr_en==1);
    	for (int i = 0; i < 35; i++) begin
        	@(posedge rd_clk);
        	if (!empty) begin
            		rd_en = 1;                
        	end
       		else begin
            		rd_en = 0;
            		$display("[%0t] FIFO EMPTY", $time);
      		end
    	end
    rd_en = 0;
    $display("READ PROCESS COMPLETE. TOTAL READ COUNT= %0d", read_count);
end			

	//read/write concurrent cases
	//
	initial begin
		#1000;
		$finish;
	end
endmodule
