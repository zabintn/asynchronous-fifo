# ----------------------------------------
# Vivado xsim-based Makefile
# Compile -> Elaborate -> Simulate flow
# ----------------------------------------

RTL_DIR   = ../rtl
TB_DIR    = ../tb
SIM_DIR   = .

TOP       = tb_top
SNAPSHOT  = tb_top_snap

RTL_SRC   = $(RTL_DIR)/afifo.sv\
						 $(RTL_DIR)/rptr_handler.sv\
						 $(RTL_DIR)/wptr_handler.sv\
						 $(RTL_DIR)/2ff_sync.sv
TB_SRC    = $(TB_DIR)/random_test.sv

.PHONY: compile elaborate simulate run clean

# Step 1: Compile RTL + testbench sources
compile:
	xvlog --sv $(RTL_SRC) $(TB_SRC)

# Step 2: Elaborate design into a simulation snapshot
elaborate: compile
	xelab $(TOP) -s $(SNAPSHOT) 

# Step 3: Run simulation
simulate: elaborate
	xsim $(SNAPSHOT) -runall


# Convenience target: does all three in order
all: compile elaborate simulate

clean:
	rm -rf xsim.dir *.log *.jou *.pb *.wdb .Xil xelab.pb webtalk*
