package DummyRAM;

import ClientServer :: *;
import FIFO :: *;
import FIFOF :: *;
import GetPut :: *;

import BDPIFunctions :: *;

typedef union tagged {
    struct {
        UInt#(32) addr;
    } ReadRq;

    struct {
        UInt#(32) addr;
        UInt#(32) data;
    } WriteRq;
} RAM_Rq deriving(Eq, Bits);

typedef union tagged {
    struct {
        UInt#(32) data;
    } ReadRs;

    union tagged {
        void      Failure;
        UInt#(32) Success;
    } WriteRs;

} RAM_Rs deriving(Eq, Bits);

interface DummyRAMSimple_ifc;
    method Action set_ram(UInt#(64) ptr);
    method UInt#(64) get_ram();
    method ActionValue#(UInt#(32)) read(UInt#(32) addr);
    method Action write(UInt#(32) addr, UInt#(32) data);
endinterface

interface DummyRAMServer_ifc;
    method Action set_ram(UInt#(64) ptr);
    method UInt#(64) get_ram();
    interface Server#(RAM_Rq, RAM_Rs) d_port;
endinterface

module mkDummyRAM(DummyRAMServer_ifc)
    provisos(
        Alias#(RAM_Rq, type_in),
        Alias#(RAM_Rs, type_out)
    );

    Reg#(Maybe#(UInt#(64))) m_ptr <- mkReg(tagged Invalid);

    FIFO#(type_in)  m_in  <- mkFIFO;
    FIFO#(type_out) m_out <- mkFIFO;

    Wire#(type_out) m_bypass <- mkWire;

    rule rprocess_rq (m_ptr matches tagged Valid .ram_ptr);
        let rq = m_in.first; m_in.deq;
        case (rq) matches
            tagged ReadRq .rrq: begin
                let a = rrq.addr;
                let ret <- read_word_DummyRAM(ram_ptr, a);
                let rs = tagged ReadRs { data : ret };
                m_bypass <= rs;
            end
            tagged WriteRq .wrq: begin
                let a = wrq.addr;
                let d = wrq.data;
                let rs = tagged WriteRs tagged Success a ;
                write_word_DummyRAM(ram_ptr, a, d);
                m_bypass <= rs;
            end
        endcase
    endrule

    rule rprocess_rs;
        m_out.enq(m_bypass);
    endrule

    method set_ram(p) = action m_ptr <= tagged Valid p; endaction;
    method get_ram if(m_ptr matches tagged Valid .p) = p;

    interface d_port = 
        interface Server;
            interface request  = toPut(m_in);
            interface response = toGet(m_out);
        endinterface;

endmodule

module mkDummyRAM_simple(DummyRAMSimple_ifc);

    Reg#(Maybe#(UInt#(64))) m_ptr <- mkReg(tagged Invalid);

    method get_ram if(m_ptr matches tagged Valid .p) = p;
    method set_ram(d) = action m_ptr <= tagged Valid d; endaction;
    method read(a)     if(m_ptr matches tagged Valid .ptr) = read_word_DummyRAM(ptr, a);
    method write(a, d) if(m_ptr matches tagged Valid .ptr) = write_word_DummyRAM(ptr, a, d);

endmodule

endpackage