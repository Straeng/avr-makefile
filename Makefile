
# ---- Project configuration --------------------------------------------------

# Name & configuration
PROGNAME	= MyProgram
CONFIG_FILE = src/myconfig.h	# optional
LDSCRIPT 	= 					# optional

# Target configuration
TARGET 		= atmega328p
CPU_FREQ 	= 16000000L

# Upload configuration
ISP_IF 		= usb				# For ISP programming 
PROG_PORT	= /dev/ttyUSB0
PROG_RATE	= 57600

# Libraries
LIB_DIRS	= #/path/to/libs/ /another/path/to/libs/
LIB_NAMES	= #lib1 lib2 lib3



# ---- Paths & file setup -----------------------------------------------------

SRCDIR		= src
OBJDIR		= obj
DISTDIR		= dist



# ---- Toolchain --------------------------------------------------------------

CC 			= avr-gcc
CPP			= avr-g++
OBJCPY 		= avr-objcopy
SIZE		= avr-size

COMP_OPT	= -Os -mcall-prologues -fno-inline-small-functions -ffunction-sections -fdata-sections
LINK_OPT	= -Os -Wl,--relax,--gc-sections,-Map=$(DISTDIR)/$(PROGNAME).map
FLAGS		= -Wall -fno-exceptions -funsigned-char -pedantic -funsigned-bitfields -fpack-struct -fshort-enums



# Object files and include paths
SOURCE_DIRS := $(shell find src/ -type d)
SRCS		:= $(foreach DIR, $(SOURCE_DIRS), $(shell find $(DIR) -iname "*.c" -o -iname "*.cpp"))
OBJS 		:= $(patsubst %.cpp, $(OBJDIR)/%.o, $(patsubst %.c, $(OBJDIR)/%.o, $(notdir $(SRCS))))
INCS		:= $(foreach DIR, $(SOURCE_DIRS), -I$(DIR))

# Source search paths
VPATH 		:= $(SOURCE_DIRS)

# Library paths
LDPATHS     := $(foreach L, $(LIB_DIRS), -L$(L)) $(foreach n, $(LIB_NAMES), -l$(n))



# ---- Compiler & linker flags ------------------------------------------------

CXXFLAGS 	:= $(COMP_OPT) $(FLAGS) -mmcu=$(TARGET) -DF_CPU=$(CPU_FREQ) $(INCS)
ifdef CONFIG_FILE
CXXFLAGS	+= -imacros $(CONFIG_FILE)
endif
CFLAGS		:= $(CXXFLAGS)
CPPFLAGS	:= $(CXXFLAGS) -fpermissive
LDFLAGS		:= $(LINK_OPT) -mmcu=$(TARGET)
ifdef LDSCRIPT
LDFLAGS		+= -T $(LDSCRIPT)
endif



# ---- Targets & rules --------------------------------------------------------

.PHONY: all
all: makedirs $(DISTDIR)/$(PROGNAME).hex

.PHONY: clean
clean:
	@rm -rf $(DISTDIR)/*
	@rm -rf $(OBJDIR)/*

# Upload program using the serial STK500 (used by Arduino bootloaders)
.PHONY: stk500_upload
stk500_upload: $(DISTDIR)/$(PROGNAME).hex
	avrdude -carduino -p$(TARGET) -P$(PROG_PORT) -b$(PROG_RATE) -Uflash:w:$<

# Upload program using ISP (AVR Dragon)
.PHONY: isp_upload
isp_upload: $(DISTDIR)/$(PROGNAME).hex
	avrdude -cdragon_isp -p$(TARGET) -P$(ISP_IF) -Uflash:w:$<

# Set fuses iusing ISP (AVR Dragon)
.PHONY: isp_fuses
isp_fuses:
	avrdude -cdragon_isp -p$(TARGET) -P$(ISP_IF) -Ulfuse:w:0xff:m -Uhfuse:w:0xdc:m -Uefuse:w:0x04:m

# Transform to hex
$(DISTDIR)/$(PROGNAME).hex: $(DISTDIR)/$(PROGNAME).elf
	@echo "Generating hex..."
	@$(OBJCPY) -O ihex $< $@

# Link 
$(DISTDIR)/$(PROGNAME).elf: $(OBJS)
	@echo "Linking..."
	@$(CC) $(LDFLAGS) -o $@ $^ $(LDPATHS)
	@$(SIZE) $@ 

# Compile
$(OBJDIR)/%.o: %.cpp
	@$(CPP) -c $< $(CPPFLAGS) -o $@

$(OBJDIR)/%.o: %.c
	@$(CC) -c $< $(CFLAGS) -o $@


makedirs:
	@mkdir -p $(OBJDIR)
	@mkdir -p $(DISTDIR)


