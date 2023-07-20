package Testbench;

import StmtFSM :: *;

import AXI4_Types :: *;
import AXI4_Master :: *;

import BDPIFunctions :: *;

module mkTestbench()
    provisos(
        NumAlias#(ram_sz, 'd8_000_000)
    );

    UInt#(32) width = 1920;
    UInt#(32) height = 1080;

    Reg#(UInt#(64)) ram_ptr <- mkRegU;
    Reg#(UInt#(64)) image_loader_ptr <- mkRegU;

    let start_addr = 'd0;

    Stmt load_image_to_ram_seq = seq
        action 
            let p <- create_ImageLoader("../../test.jpg");
            image_loader_ptr <= p;
        endaction
        write_to_mem_seq_ImageLoader(image_loader_ptr, ram_ptr, start_addr);
    endseq;

    Stmt load_image_to_ram_interleaved = seq
        action 
            let p <- create_ImageLoader("../../test.jpg");
            image_loader_ptr <= p;
        endaction
        write_to_mem_interleaved_ImageLoader(image_loader_ptr, ram_ptr, start_addr);
    endseq;

    Stmt ram_to_image_seq = seq
        mem_to_file_seq_ImageWriter(ram_ptr, width, height, "results/result.jpg", start_addr);
    endseq;

    Stmt ram_to_image_interleaved = seq
        mem_to_file_interleaved_ImageWriter(ram_ptr, width, height, "results/result.jpg", start_addr);
    endseq;

    FSM image_to_ram_fsm <- mkFSM(load_image_to_ram_interleaved);
    FSM ram_to_image_fsm <- mkFSM(ram_to_image_interleaved);

    Stmt s = seq
        action
            let p <- create_DummyRAM(fromInteger(valueof(ram_sz)));
            ram_ptr <= p;
        endaction
        image_to_ram_fsm.start();
        await(image_to_ram_fsm.done());
        ram_to_image_fsm.start();
        await(ram_to_image_fsm.done());
    endseq;

    mkAutoFSM(s);

endmodule

endpackage