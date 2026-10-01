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

	// Writer
	initial begin
		wr_clk=0;
		rd_clk=0;
		w_arst_n=0;
		r_arst_n=0;
		wr_en=0;
		rd_en=0;
		#20;
		w_arst_n=1;
		r_arst_n=1;
			
		forever begin
			@(posedge wr_clk);
			
			if (!full) begin
				wr_en   <= $urandom_range(0,1);
				wr_data <= $urandom;
			end
			else
				wr_en <= 0;
		end
	end

	// Reader
	initial begin
		@(posedge r_arst_n);
		
		forever begin
			@(posedge rd_clk);
			
			if (!empty)
				rd_en <= $urandom_range(0,1);
			else
				rd_en <= 0;
		end	
	end
	

	initial begin
		#1000;
		$finish;
	end

	endmodule

