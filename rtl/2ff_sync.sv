`timescale 1ns/1ps

module sync_2ff #(parameter FIFO_DEPTH=16,
        ADDR_WIDTH=$clog2(FIFO_DEPTH)
	)(

        input logic [ADDR_WIDTH:0] async_in,
        input logic clk,
        input logic rstn,
        output logic [ADDR_WIDTH:0]  sync_out
        );

        logic [ADDR_WIDTH:0] metastable;

        always @(posedge clk or negedge rstn) begin
                if(!rstn) begin
                        metastable<=0;
                        sync_out<=0;
                end

                else begin
                        metastable<=async_in;
                        sync_out<=metastable;
                end
        end
endmodule                         
