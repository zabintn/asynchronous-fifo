`timescale 1ns/1ps

module async_fifo #(parameter DATA_WIDTH=32,
	FIFO_DEPTH=16,
	ADDR_WIDTH=$clog2(FIFO_DEPTH)
	)(
		//write interface

		input wr_clk,
		input w_arst_n,
		input wr_en,
		input [DATA_WIDTH-1:0] wr_data,
		output logic full,

		//read interface
		
		input rd_clk,
		input r_arst_n,
		input rd_en,
		output logic [DATA_WIDTH-1:0] rd_data,
		output logic empty
		);

		logic [DATA_WIDTH-1:0] memory [0:FIFO_DEPTH-1];
		
		logic [ADDR_WIDTH:0] wptr_bin, wptr_gray;
		logic [ADDR_WIDTH:0] rptr_bin, rptr_gray;
		
		logic [ADDR_WIDTH:0] wptr_gray_sync;
		logic [ADDR_WIDTH:0] rptr_gray_sync;
		
	//write pointer handler plug in
	

	wptr_handler #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) u_wptr_handler(
	.wr_clk(wr_clk),
       	.wr_en(wr_en), 
	.w_arst_n(w_arst_n),
	.rptr_gray_sync(rptr_gray_sync),
	.wptr_bin(wptr_bin),
	.wptr_gray(wptr_gray),
	.full(full)
	);	
	
	//read pointer handler plug in
	
	rptr_handler #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) u_rptr_handler(
		.rd_clk(rd_clk),
		.rd_en(rd_en),
		.r_arst_n(r_arst_n),
		.wptr_gray_sync(wptr_gray_sync),
		.rptr_gray(rptr_gray),
		.rptr_bin(rptr_bin),
		.empty(empty)
		);

	//2 FF synchronizer instantiation (read clk domain to write clk domain)
	
	sync_2ff #(.FIFO_DEPTH(FIFO_DEPTH)) r2w_sync2ff(
	       .clk(wr_clk), 
	       .rstn(w_arst_n),
	       .async_in(rptr_gray), 
	       .sync_out(rptr_gray_sync)
	       );	

	// 2 FF synchronizer instantiation (write clk domain to read clk
	// domain)

 	sync_2ff #(.FIFO_DEPTH(FIFO_DEPTH)) w2r_sync2ff(
		.clk(rd_clk),
		.rstn(r_arst_n),
		.async_in(wptr_gray),
		.sync_out(wptr_gray_sync)
		);

	
	//write operation
	

	always @(posedge wr_clk or negedge w_arst_n) begin
		if (!w_arst_n) begin
			for (int i = 0; i < FIFO_DEPTH; i++)
				memory[i] <= '0;
		end
	
		else if(wr_en && !full) begin
		
		memory[wptr_bin[ADDR_WIDTH-1:0]]<=wr_data;
		end
	end

	//read operation
	

	always @(posedge rd_clk or negedge r_arst_n) begin

		if (!r_arst_n) begin
			rd_data<= '0;
		end
		else if(rd_en && !empty) begin
			rd_data<=memory[rptr_bin[ADDR_WIDTH-1:0]];
		end
	end

endmodule

