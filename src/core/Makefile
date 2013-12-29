CXX = g++-4.7
CXXFLAGS = -std=c++11 -O3 -I. -DUSE_SIMT_LSU -DUSE_CACHE #-DDEBUG # -g
LDLIBS = -Lchdl -lchdl
#ARCH = 4w16/16/1
ARCH = 4w16/16/8
#ARCH = 8w8/8/1

dump.vcd : harmonica-vl
	#./harmonica-vl

harmonica-vl : harmonica.v testbench.v # divider.v #vgacont.v
	#iverilog -o harmonica-vl -c file_list.txt -s top
	#iverilog -o harmonica-vl harmonica.v testbench.v # divider.v asyncmul.v #vgacont.v

harmonica.ps : harmonica.dot
	dot -Tps -o harmonica.ps harmonica.dot

harmonica.dot harmonica.v harmonica.vcd : harmonica rom.hex
	./harmonica

harmonica: harmonica.o pipeline.o

harmonica.o : harmonica.cpp pipeline.h funcunit.h harpinst.h lsu.h\
              regfile.h fpu.h bpred.h config.h

pipeline.o  : pipeline.cpp pipeline.h

rom.hex : rom.bin
	hexdump -v -e '1/4 "%08x" "\n"' rom.bin > rom.hex
#	hexdump -v -e '2/4 "%08x " "\n"' rom.bin | \
#          sed 's/\([0-9a-f]*\) \([0-9a-f]*\)/\2\1/' > rom.hex

rom.bin : rom.HOF
	harptool -L --arch $(ARCH) -o rom.bin rom.HOF

rom.HOF : rom.s
	harptool -A --arch $(ARCH) -o rom.HOF rom.s

clean:
	rm -f harmonica harmonica-vl harmonica.vcd dump.vcd *~ \
              harmonica.v harmonica.dot harmonica.ps *.o \
              rom.hex rom.bin rom.HOF
