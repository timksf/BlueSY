package FilterTest;

import StmtFSM :: *;
import GetPut :: *;
import ClientServer :: *;
import Connectable :: *;
import BUtils :: *;

import BlueAXI :: *;
import BlueLib :: *;

import Types :: *;
import BDPIFunctions :: *;
import Filter :: *;
import AXI4_DummyRAM_Slave :: *;

String input_image_path = "../../gray.jpg";//`IM_PATH;
String output_image_path = "results/result.jpg";//`RES_PATH;

typedef 640 InputWidth;
typedef 480 InputHeight;

module mkFilterTest()
    provisos(
        NumAlias#(ram_sz, 'd1_000_000),
        NumAlias#(amount, TMul#(InputWidth, InputHeight)), //data amount in words
        NumAlias#(amount_bytes, TMul#(8, amount)),
        NumAlias#(amountw, TLog#(amount_bytes))
    );

    AXI4DummyRAM_ifc#(ram_sz, AXIDataWidth) ram <- mkAXI4DummyRAM(False);

    Filter_ifc#(1, amountw) filter <- mkNegativeFilter;
    AXI4_Lite_Master_Rd#(ConfigAddrWidth, ConfigDataWidth) config_rd <- mkAXI4_Lite_Master_Rd(0);
    AXI4_Lite_Master_Wr#(ConfigAddrWidth, ConfigDataWidth) config_wr <- mkAXI4_Lite_Master_Wr(0);

    Reg#(Bool) finish <- mkReg(False);
    Reg#(UInt#(64)) ram_ptr <- mkRegU;
    Reg#(UInt#(64)) image_loader_ptr <- mkRegU;

    UInt#(32) width = fromInteger(valueof(InputWidth));
    UInt#(32) height = fromInteger(valueof(InputHeight));
    UInt#(32) pixels = fromInteger(valueof(amount));

    mkConnection(ram.fab_rd, filter.fab_mem_rd);
    mkConnection(ram.fab_wr, filter.fab_mem_wr);
    mkConnection(config_rd.fab, filter.fab_config_rd);
    mkConnection(config_wr.fab, filter.fab_config_wr);

    UInt#(64) input_addr = 'd0;
    UInt#(64) output_addr = fromInteger(valueof(amount_bytes));

    Action expectOKAY = action 
        let r <- axi4_lite_write_response(config_wr);
        if(r != OKAY) begin
            printColorTimed(RED, $format("Got bad write response from config"));
            $finish;
        end
    endaction;

    Stmt image_to_ram = seq
        action 
            let p <- create_ImageLoader(input_image_path);
            image_loader_ptr <= p;
        endaction
        write_to_mem_gray_packed_ImageLoader(image_loader_ptr, ram_ptr, input_addr);
    endseq;

    Stmt ram_to_image = seq
        mem_to_file_gray_packed_ImageWriter(ram_ptr, width, height, output_image_path, output_addr >> 3);
    endseq;

    FSM image_to_ram_fsm <- mkFSM(image_to_ram);
    FSM ram_to_image_fsm <- mkFSM(ram_to_image);

    Stmt s = seq
        ram_ptr <= ram.ram_instance();
        image_to_ram_fsm.start();
        await(image_to_ram_fsm.done());

        printColorTimed(BLUE, $format("Finished loading image to memory"));

        //configure filter
        axi4_lite_write(config_wr, fromInteger(offs_input_addr), pack(input_addr));
        expectOKAY;
        axi4_lite_write(config_wr, fromInteger(offs_pixel_amount), cExtend(pixels));
        expectOKAY;
        axi4_lite_write(config_wr, fromInteger(offs_output_addr), pack(output_addr));
        expectOKAY;
        axi4_lite_write(config_wr, fromInteger(offs_pixel_layout), zeroExtend(pack(PACKED)));
        expectOKAY;

        printColorTimed(GREEN, $format("Filter supposed to write to %0x", output_addr));

        //start filter
        axi4_lite_write(config_wr, fromInteger(offs_start), ?);
        delay(10);

        //wait until filter is finished
        while(!finish) seq
            axi4_lite_read(config_rd, fromInteger(offs_finished));
            action
                let r <- axi4_lite_read_response(config_rd);
                if(unpack(r[0])) begin
                    finish <= True;
                    printColorTimed(GREEN, $format("Filter finished"));
                end
            endaction
        endseq

        ram_to_image_fsm.start();
        await(ram_to_image_fsm.done());
    endseq;

    mkAutoFSM(s);

endmodule

endpackage