package Types;

typedef Bit#(32) Word;

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
    RGB, //weighted sum of RGB values
    SRGB //weighted sum of linearized sRGB values
} ColorMode deriving(Eq, Bits);

typedef enum {
    NORMAL, //one word in memory equals one stored value
    PACKED //the 3 8-bit values of a pixel are stored in a single word
} PixelLayout deriving(Eq, Bits);

typedef struct {
    UInt#(8) r;
    UInt#(8) g;
    UInt#(8) b;
} RGB deriving(Eq, Bits);

endpackage