package TestAXI4DummyRAM;

import StmtFSM :: *;
import ClientServer :: *;
import GetPut :: *;
import Connectable :: *;
import List :: *;
import Vector :: *;

import BlueAXI :: *;
import BlueLib :: *;

import BDPIFunctions :: *;
import AXI4_DummyRAM_Slave :: *;

String input_image_path = `IM_PATH;
String output_image_path = `RES_PATH;

typedef 1920 InputWidth;
typedef 1080 InputHeight;

module mkTestAXI4DummyRAM();
    
    mkPassthroughTest();
    
endmodule

module mkPassthroughTest(Empty) 
    provisos(
        NumAlias#(ram_sz, 'd8_000_000),
        NumAlias#(amount, TMul#(InputWidth, InputHeight)), //data amount in words (32bit)
        NumAlias#(dataw, 128),
        NumAlias#(addrw, 32),
        NumAlias#(amount_bytes, TMul#(4, amount)),
        NumAlias#(amountw, TLog#(amount_bytes))
    );

    //Memory slave
    AXI4DummyRAM_ifc#(ram_sz, dataw) dut <- mkAXI4DummyRAM(False);
    //Read Master
    Axi4MasterRead#(addrw, dataw, 1, 0, amountw) mem_master_rd <- mkAxi4MasterRead(8, 8, True, 128, True, 8, True, True);
    //Write master
    Axi4MasterWrite#(addrw, dataw, 1, 0, amountw) mem_master_wr <- mkAxi4MasterWrite(8, 8, True, 256, True, 1, True, 2);

    mkConnection(dut.fab_rd, mem_master_rd.fab);
    mkConnection(dut.fab_wr, mem_master_wr.fab);

    UInt#(32) write_addr = fromInteger(valueof(amount)) << 2; //byte address for AXI requests

    //requests for memory regions
    AxiRequest#(32, amountw) rq_rd = AxiRequest { address: 0, bytesToTransfer: fromInteger(valueof(amount_bytes)), region: 0 };
    AxiRequest#(32, amountw) rq_wr = AxiRequest { address: pack(write_addr), bytesToTransfer: fromInteger(valueof(amount_bytes)), region: 0 };

    Reg#(UInt#(64)) ram_ptr <- mkRegU;
    Reg#(UInt#(64)) image_loader_ptr <- mkRegU;
    Reg#(UInt#(64)) image_writer_ptr <- mkRegU;

    //use to preload ram model with valid image data
    Stmt load_image_to_ram_interleaved = seq
        action 
            let p <- create_ImageLoader(input_image_path);
            image_loader_ptr <= p;
        endaction
        write_to_mem_interleaved_ImageLoader(image_loader_ptr, ram_ptr, 'h0);
    endseq;

    Stmt ram_to_image_interleaved = seq
        mem_to_file_interleaved_ImageWriter(ram_ptr, fromInteger(valueof(InputWidth)), fromInteger(valueof(InputHeight)), output_image_path, write_addr >> 2);
    endseq;

    FSM image_to_ram_fsm <- mkFSM(load_image_to_ram_interleaved);
    FSM ram_to_image_fsm <- mkFSM(ram_to_image_interleaved);

    Reg#(UInt#(32)) read_cnt <- mkReg(0);

    rule fwd_rd_to_wr;
        let r <- mem_master_rd.server.response.get();
        mem_master_wr.data.put(r);
        read_cnt <= read_cnt + 1;
    endrule

    /*
        This FSM loads an image to the RAM model with C++ functions.
        It then starts reading the region where the image is stored with an AXI master.
        The read master forwards immediately to the write master, which in turn
        writes to an offset region in the RAM model.
        When all AXI transactions are complete, C++ functions are again used to write the 
        written region to an output image file.
        The forwarding happens in the fwd_rd_to_wr rule.
    */
    Stmt pass_through = seq
        printColorTimed(GREEN, $format("Starting main FSM"));
        //load image to ram model
        ram_ptr <= dut.ram_instance();
        image_to_ram_fsm.start();
        await(image_to_ram_fsm.done());
        printColorTimed(GREEN, $format("Finished loading image to RAM"));
        printColorTimed(YELLOW, $format("Wrote %0d bytes", valueof(amount_bytes)));

        //load data from ram model with AXI master and write to different region
        mem_master_rd.server.request.put(rq_rd);
        mem_master_wr.request.put(rq_wr);
        await(mem_master_rd.active());
        await(!mem_master_rd.active());
        printColorTimed(GREEN, $format("Finished reading image from RAM"));

        await(!mem_master_wr.active());
        printColorTimed(GREEN, $format("Finished writing image to RAM"));
        printColorTimed(YELLOW, $format("Forwarded %0d packets of width %0d totaling %0d bytes", read_cnt, valueof(dataw), (read_cnt*fromInteger(valueof(dataw))) >> 3));
        ram_to_image_fsm.start();
        await(ram_to_image_fsm.done());
    endseq;

    mkAutoFSM(pass_through);

endmodule

endpackage