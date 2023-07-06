
OBJS=dummy_ram image_loader image_writer
OBJ_FILES=$(patsubst %,%.o, $(OBJS))
OBJ_FILES_BSV=$(patsubst %,%_bsv.o, $(OBJS))

override CPPFLAGS+= -O3 -std=c++17

$(info $(CPPFLAGS))

PRJ_ROOT=../../../src

LIBS=CImg
LIB_DIRS=$(patsubst %, ../../libraries/%/, $(LIBS))
LIB_INCLUDE=$(patsubst %, -I %, $(LIB_DIRS))

LINK_TO=png z X11 pthread
LINK_OPTS=$(patsubst %,-l %, $(LINK_TO))

test: test.cpp $(OBJ_FILES)
	$(CC) $(LIB_INCLUDE) -I $(PRJ_ROOT) -o test_exec test.cpp *.o $(LINK_OPTS)

$(OBJ_FILES): %.o : %.cpp
	$(CC) -c $(CPPFLAGS) $(LIB_INCLUDE) -I $(PRJ_ROOT) -Wall $< -o $@ $(LINK_OPTS)

clean: 
	rm -r *.o

bsv_objs: $(OBJ_FILES)
	@echo "Building object files for BSV"