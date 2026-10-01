`timescale 1ns/1ps

module rptr_handler #(parameter DATA_WIDTH= 32, FIFO_DEPTH=16, ADDR_WIDTH= $clog2(FIFO_DEPTH))
        (
                input rd_en,
                input rd_clk,
                input r_arst_n,
                input [ADDR_WIDTH:0] wptr_gray_sync,


                output logic [ADDR_WIDTH:0]  rptr_bin, rptr_gray,
                output logic empty
        );


        always@(posedge rd_clk or negedge r_arst_n) begin

                if(!r_arst_n) begin
                        rptr_bin<= '0;
                        rptr_gray<='0;
                end

                else if (rd_en && !empty) begin
                        rptr_bin<=rptr_bin+1;
                        rptr_gray<= (rptr_bin+1) ^ ((rptr_bin+1)>>1);
                end
        end

	
	assign empty= (rptr_gray==wptr_gray_sync);


endmodule

