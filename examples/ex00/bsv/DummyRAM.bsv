package DummyRAM;

import ClientServer :: *;
import FIFO :: *;
import FIFOF :: *;
import GetPut :: *;

import BDPIFunctions :: *;

interface DummyRAMSimple_ifc;
    method Action set_ram(UInt#(64) ptr);
    method UInt#(64) get_ram();
    method ActionValue#(UInt#(64)) read(UInt#(64) addr);
    method Action write(UInt#(64) addr, UInt#(64) data);
endinterface

module mkDummyRAM_simple(DummyRAMSimple_ifc);

    Reg#(Maybe#(UInt#(64))) m_ptr <- mkReg(tagged Invalid);

    method get_ram if(m_ptr matches tagged Valid .p) = p;
    method set_ram(d) = action m_ptr <= tagged Valid d; endaction;
    method read(a)     if(m_ptr matches tagged Valid .ptr) = read_word_DummyRAM(ptr, a);
    method write(a, d) if(m_ptr matches tagged Valid .ptr) = write_word_DummyRAM(ptr, a, d);

endmodule

endpackage