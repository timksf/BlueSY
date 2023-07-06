OS = LINUX
CMP = bsc

NAME ?= Testbench
TOP_FILE=$(NAME).bsv
MOD_NAME := mk$(NAME)
EXE = $(MOD_NAME)_sim
EXE_V = $(MOD_NAME)_simv

BUILD_DIR=build
SIM_DIR=sim

IMG_INPUT?=../../test.jpg
IMG_OUTPUT?=results/result.jpg

ifeq ($(IMG_INPUT),)
	$(error No input image specified.)
endif

ifeq ($(IMG_OUTPUT),)
	$(error No output image specified.)
endif

VERILOG_DIR =verilog
BUILD_DIR_V = $(BUILD_DIR)/verilog
SIM_DIR_V = $(SIM_DIR)/verilog

VSIM = iverilog
CLEAR =
ARGS ?= -Xc++ -Wno-format-truncation -Xc++ -Wno-dangling-else #-show-schedule -aggressive-conditions
ARGSC ?= -D IM_PATH=\"$(IMG_INPUT)\" -D RES_PATH=\"$(IMG_OUTPUT)\"# -show-schedule -aggressive-conditions 

$(info $(ARGSC))

BLUEAXI_DIR=../../libraries/BlueAXI/src
BLUELIB_DIR=../../libraries/BlueLib/src

BLUEIMPORT=$(BLUEAXI_DIR):$(BLUELIB_DIR):+

BDPIDIR=../BDPI
BDPI_FILES=dummy_ram image_loader image_writer
BDPI_LOCS=$(patsubst %,$(BDPIDIR)/%, $(BDPI_FILES))
OBJ_FILES=$(patsubst %,%.o, $(BDPI_LOCS))
CPPFLAGS=-O3 -std=c++17 -fPIC 

LIBS=CImg map-macro
LIB_DIRS=$(patsubst %,libraries/%/, $(LIBS))
LIB_INCLUDE=$(patsubst %, -I %, $(LIB_DIRS))

LINK_TO=png z X11 pthread
LINK_OPTS=$(patsubst %,-l %, $(LINK_TO))

NO_DELETE=$(BUILD_DIR)/AXI* $(BUILD_DIR)/Blue* $(BUILD_DIR)/GenericAxi* $(BUILD_DIR)/Packet*

BUILD_DELETE=$(filter-out $(wildcard $(NO_DELETE)), $(wildcard $(BUILD_DIR)/*))

all: $(EXE)

allV: $(EXE_V)

test:
	@[ -z $(filter-out $(wildcard $(NO_DELETE)), $(wildcard $(BUILD_DIR)/*)) ] && echo ZERO || echo NOTZERO

$(BUILD_DIR)/$(MOD_NAME).ba: $(TOP_FILE)
	@mkdir -p $(BUILD_DIR)
	$(CMP) -p $(BLUEIMPORT) \
			-bdir $(BUILD_DIR) \
			-sim -g $(MOD_NAME) \
			$(ARGSC) \
			-u $<
# $(ARGSC) \

clean:
	$(MAKE) -C $(BDPIDIR) clean
	rm -f $(EXE) $(EXE_V) *.so *_sim *.sched
	rm -rf $(SIM_DIR) $(VERILOG_DIR)
	@[ -n "${BUILD_DELETE}" ] && rm -r $(BUILD_DELETE) || echo "No build files to delete"
	@[ -e "${IMG_OUTPUT}" ] && rm -r $(IMG_OUTPUT) || echo "No result files to delete"

$(OBJ_FILES): %.o : %.cpp
	$(MAKE) -C $(BDPIDIR) bsv_objs CPPFLAGS="-fPIC"


$(EXE): $(BUILD_DIR)/$(MOD_NAME).ba $(OBJ_FILES) 
	@mkdir -p $(SIM_DIR)
	$(CMP) -p $(BLUEIMPORT) \
			-bdir $(BUILD_DIR) \
			-simdir $(SIM_DIR) \
			$(LINK_OPTS) \
			-sim -e $(MOD_NAME) \
			$(ARGS) \
			-o $@ \
			$(OBJ_FILES) \

sim: $(EXE)
	@echo Starting Bluesim simulation...
	./$<