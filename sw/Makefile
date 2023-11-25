#
# General makefile that makes all targets
#
# First the `srec2vhdl` and `upload`
# are made. `srec2vhdl` is needed for the
# next build steps. Next is the library.
# Other targets depend on it.
#
# NOTE: the path to the RISC-V GNU C/C++ compiler
# must be in in the PATH environment variable
#

SUBDIRS = add64 \
          assembler \
          basel_problem \
          bootloader \
          clock \
          complex \
          coremark \
          ctor_c \
          ctor_cpp \
          dhrystone \
          double \
          exp \
          fatfs \
          flash \
          float \
          FreeRTOSdemo \
          global \
          hex_display \
          i2c1findslaves \
          i2c1lis3dh \
          i2c1ssd1315 \
          i2c1tmp102 \
          interrupt_direct \
          interrupt_vectored \
          interval \
          ioadd \
          linked_list \
          malloc \
          mcountinhibit \
          monitor \
          mult \
          mxhw \
          qsort \
          riemann_left \
          shift \
          spi1readeeprom \
          spi1softnss \
          spi1speed \
          spi1writeeeprom \
          sprintf \
          string \
          structio \
          testexceptions \
          testio \
          timer1 \
          timer2ic \
          timer2pwm \
          trig \
          uart1_cpp \
          uart1_printf \
          uart1_printlonglong \
          uart1_sprintf \
          uart1_test

.PHONY: all bin $(SUBDIRS) clean

all: bin $(SUBDIRS)

bin:
	if [ ! -d bin ]; then mkdir bin; fi
	$(MAKE) -C srec2vhdl all
	cp srec2vhdl/srec2vhdl bin
	$(MAKE) -C upload all
	cp upload/upload bin
	$(MAKE) -C lib all

$(SUBDIRS): bin
	$(MAKE) -C $@ all

clean:
	$(MAKE) -C srec2vhdl clean
	$(MAKE) -C upload clean
	rm -rf bin
	$(MAKE) -C lib clean
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
