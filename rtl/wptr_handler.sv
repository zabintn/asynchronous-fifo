`timescale 1ns/1ps

module wptr_handler #(parameter DATA_WIDTH= 32, FIFO_DEPTH=16, ADDR_WIDTH= $clog2(FIFO_DEPTH))
	( 
		input wr_en,
		input wr_clk,
		input w_arst_n,
		input [ADDR_WIDTH:0] rptr_gray_sync,

		
		output logic [ADDR_WIDTH:0]  wptr_bin, wptr_gray,
		output logic full
	);
	
		
	always@(posedge wr_clk or negedge w_arst_n) begin
		
		if(!w_arst_n) begin
			wptr_bin<= '0;
			wptr_gray<='0;
		end

		else if (wr_en && !full) begin
			wptr_bin<=wptr_bin+1;
			wptr_gray<= (wptr_bin+1) ^ ((wptr_bin+1)>>1);
		end
	end

	
	assign full=( (wptr_gray[ADDR_WIDTH]!=rptr_gray_sync[ADDR_WIDTH]) && (wptr_gray[ADDR_WIDTH-1]!=rptr_gray_sync[ADDR_WIDTH-1] && wptr_gray[ADDR_WIDTH-2:0] == rptr_gray_sync[ADDR_WIDTH-2:0]));


endmodule
