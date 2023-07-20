package Types;

typedef 128 AXIDataWidth; //zynqmp PS width
typedef 64 WordWidth;
typedef 64 MemoryAddrWidth;

typedef TDiv#(WordWidth, 8) BytesPerWord;
typedef TDiv#(AXIDataWidth, 8) BytesPerXfer;

typedef Bit#(WordWidth) Word;
typedef Bit#(MemoryAddrWidth) MemoryAddress;

typedef struct {
    Bit#(addr_width) index_min;
    Bit#(addr_width) index_max;
} AddressRange#(numeric type addr_width) deriving(Eq, Bits, FShow);

instance DefaultValue#(AddressRange#(addr_width));
    defaultValue = 
        AddressRange {
            index_min : 0,
            index_max : 0
        };
endinstance

typedef enum {
    NORMAL, //one word in memory equals one pixel
    PACKED  //there are as many full pixels stored per word as possible
} PixelLayout deriving(Eq, Bits);

endpackage