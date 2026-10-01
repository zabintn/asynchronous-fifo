`timescale 1ns/1ps
module tb_top;

    parameter DATA_WIDTH = 32;
    parameter FIFO_DEPTH = 16;

    logic wr_clk, rd_clk;
    logic w_arst_n, r_arst_n;
    logic wr_en, rd_en;
    logic [DATA_WIDTH-1:0] wr_data, rd_data;
    logic full, empty;

    int error_count = 0;
    int write_count = 0;
    int read_count  = 0;

    // Reference model — a simple queue holding expected values in order
    logic [DATA_WIDTH-1:0] expected_q[$];

    // Independent, unrelated clock periods — exercises spec req #4
    always #5  wr_clk = ~wr_clk;   // 10ns period
    always #7  rd_clk = ~rd_clk;   // 14ns period

    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) DUT (
        .wr_clk(wr_clk), .w_arst_n(w_arst_n), .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rd_clk(rd_clk), .r_arst_n(r_arst_n), .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
    );

    // Reset
    initial begin
        wr_clk = 0; rd_clk = 0;
        w_arst_n = 0; r_arst_n = 0;
        wr_en = 0; rd_en = 0;
        #20;
        w_arst_n = 1;
        r_arst_n = 1;
        $display("[%0t] RESET DEASSERTED", $time);
    end

    // Check 1: reset behavior — full/empty must be sane immediately after reset
    initial begin
        @(posedge w_arst_n);
        @(posedge wr_clk);
        if (full !== 1'b0) begin
            $display("[%0t] ERROR: full asserted right after reset!", $time);
            error_count++;
        end
        @(posedge r_arst_n);
        @(posedge rd_clk);
        if (empty !== 1'b1) begin
            $display("[%0t] ERROR: empty NOT asserted right after reset!", $time);
            error_count++;
        end
        else
            $display("[%0t] CHECK PASSED: post-reset state correct (empty=1, full=0)", $time);
    end

    // Write process — write until full, pushing expected values into the reference queue
    initial begin
        wait(w_arst_n);
        repeat (30) begin
            @(posedge wr_clk);
            if (!full) begin
                wr_en   = 1;
                wr_data = $urandom;
                expected_q.push_back(wr_data);
                write_count++;
                $display("[%0t] WRITE #%0d data=%0h", $time, write_count, wr_data);
            end
            else begin
                wr_en = 0;
                $display("[%0t] FIFO FULL - write skipped", $time);
            end
        end
        @(posedge wr_clk);
        wr_en = 0;
    end

    // Read process — read whenever not empty, check against reference queue
    initial begin
        wait(r_arst_n);
        #50;   // let some writes land first, to also exercise concurrent read/write
        forever begin
            @(posedge rd_clk);
            if (!empty) begin
                rd_en = 1;
            end
            else begin
                rd_en = 0;
            end
        end
    end

    // Separate process to check rd_data one cycle after rd_en was asserted (matches registered read latency)
    logic rd_en_d;
    always @(posedge rd_clk) rd_en_d <= rd_en;

    always @(posedge rd_clk) begin
        if (rd_en_d) begin
            logic [DATA_WIDTH-1:0] exp;
            if (expected_q.size() == 0) begin
                $display("[%0t] ERROR: read occurred but reference queue is empty!", $time);
                error_count++;
            end
            else begin
                exp = expected_q.pop_front();
                read_count++;
                if (rd_data !== exp) begin
                    $display("[%0t] ERROR: READ #%0d MISMATCH - got=%0h expected=%0h", $time, read_count, rd_data, exp);
                    error_count++;
                end
                else begin
                    $display("[%0t] READ #%0d MATCH data=%0h", $time, read_count, rd_data);
                end
            end
        end
    end

    // End of test
    initial begin
        #2000;
        $display("=======================================");
        $display("TEST COMPLETE: writes=%0d reads=%0d errors=%0d", write_count, read_count, error_count);
        if (error_count == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");
        $display("=======================================");
        $finish;
    end

endmodule
