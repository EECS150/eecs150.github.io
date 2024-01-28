
IVERILOG = iverilog
SRCS = *.v

TOP = bit_serial_receiver_tb
OUT = test.out
VCD = test.vcd

$(OUT): $(SRCS)
	$(IVERILOG) $(SRCS) -s $(TOP) -o test.out

run: $(OUT)
	./test.out

wave: $(OUT)
	gtkwave $(VCD)

clean:
	rm -rf *.vcd *.out
