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

        int write_count;
        int read_count;
        int full_count;
        int empty_count;
        int mismatch_count;

        // scoreboard: values that were actually written, in FIFO order
        logic [DATA_WIDTH-1:0] expected_q[$];
        bit read_pending;

        //clock generation
        //write clock, 10ns
        always #7 wr_clk=~wr_clk;
        //read clock, 16ns
        always #5 rd_clk=~rd_clk;

        //module instantiation
        async_fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) DUT (
                .wr_clk(wr_clk), .w_arst_n(w_arst_n), .wr_en(wr_en), .wr_data(wr_data), .full(full),
                .rd_clk(rd_clk), .r_arst_n(r_arst_n), .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
                );

        //dump data for waveform
        initial begin
                $dumpfile("Waveform.vcd");
                $dumpvars(0, tb_top);
        end

        // Writer - fully random enable, pushes what it actually wrote into the scoreboard
        initial begin
                logic wr_en_next;
                logic [DATA_WIDTH-1:0] wr_data_next;
                wr_clk=0;
                rd_clk=0;
                w_arst_n=0;
                r_arst_n=0;
                wr_en=0;
                rd_en=0;
                #20;
                w_arst_n=1;
                r_arst_n=1;
                write_count=0;
                forever begin
                        @(posedge wr_clk);
                        if (!full) begin
                                wr_en_next   = $urandom_range(0,1);
                                wr_data_next = 32'hBEEF_0000 + write_count;
                                wr_en   <= wr_en_next;
                                wr_data <= wr_data_next;
                                if (wr_en_next) begin
                                        expected_q.push_back(wr_data_next);
                                        write_count++;
                                        $display("[%0t] WRITE #%0d data=%0h", $time, write_count, wr_data_next);
                                end
                        end
                        else begin
                                wr_en <= 0;
                                full_count++;
                                $display("[%0t] FIFO FULL", $time);
                        end
                end
        end

        // Reader - fully random enable, checks rd_data against scoreboard exactly
        // one rd_clk cycle after the read that fetched it
        initial begin
                logic rd_en_next;
                logic [DATA_WIDTH-1:0] expected;
                read_pending = 0;
                @(posedge r_arst_n);
                forever begin
                        @(posedge rd_clk);
                        #1;   // let rd_data's registered update settle before sampling

                        if (read_pending) begin
                                read_pending = 0;
                                expected = expected_q.pop_front();
                                if (rd_data !== expected) begin
                                        $display("[%0t] READ #%0d MISMATCH: expected %0h got %0h",
                                                $time, read_count, expected, rd_data);
                                        mismatch_count++;
                                end
                                else begin
                                        $display("[%0t] READ #%0d data=%0h PASS", $time, read_count, rd_data);
                                end
                        end

                        if (!empty) begin
                                rd_en_next = $urandom_range(0,1);
                                rd_en <= rd_en_next;
                                if (rd_en_next) begin
                                        read_count++;
                                        read_pending = 1;
                                end
                        end
                        else begin
                                rd_en <= 0;
                                empty_count++;
                                $display("[%0t] FIFO EMPTY", $time);
                        end
                end
        end

        initial begin
                #5000;
                $display("\nRANDOM TEST COMPLETE");
                $display("TOTAL WRITES    = %0d", write_count);
                $display("TOTAL READS     = %0d", read_count);
                $display("FULL  OBSERVED  %0d cycles", full_count);
                $display("EMPTY OBSERVED  %0d cycles", empty_count);
                $display("MISMATCHES      = %0d", mismatch_count);
                $display("UNREAD IN QUEUE = %0d", expected_q.size());

                if (mismatch_count == 0)
                        $display("\n*** RANDOM TEST PASSED ***\n");
                else
                        $display("\n*** RANDOM TEST FAILED: %0d mismatch(es) ***\n", mismatch_count);

                $finish;
        end
endmodule
