package Filter;

import ClientServer :: *;
import GetPut :: *;
import StmtFSM :: *;
import FIFO :: *;
import SpecialFIFOs :: *;
import FixedPoint :: *;
import Vector :: *;

import BlueAXI :: *;
import BlueLib :: *;

import Types :: *;

typedef Bit#(8) Grayscale;
typedef Bit#(0) Token;

typedef 10 ConfigAddrWidth;
typedef 64 ConfigDataWidth;

//AXI4Lite config mmio offsets
Integer offs_start           = 'h00;
Integer offs_finished        = 'h08;
Integer offs_input_addr      = 'h10;
Integer offs_output_addr     = 'h20;
Integer offs_pixel_amount    = 'h30;
Integer offs_pixel_layout    = 'h40;

interface Filter_ifc#(numeric type id_width, numeric type amount_width);
    //memory interface
    (* prefix="M_AXI_mem" *)
    interface AXI4_Master_Rd_Fab#(MemoryAddrWidth, AXIDataWidth, id_width, 0) fab_mem_rd;
    (* prefix="M_AXI_mem" *)
    interface AXI4_Master_Wr_Fab#(MemoryAddrWidth, AXIDataWidth, id_width, 0) fab_mem_wr;

    //config interface
    (* prefix="S_AXI_cfg" *)
    interface AXI4_Lite_Slave_Rd_Fab#(ConfigAddrWidth, ConfigDataWidth) fab_config_rd;
    (* prefix="S_AXI_cfg" *)
    interface AXI4_Lite_Slave_Wr_Fab#(ConfigAddrWidth, ConfigDataWidth) fab_config_wr;
endinterface

interface InternalConfig_ifc;

    interface Get#(Token) start;
    method PixelLayout pixel_layout();
    method MemoryAddress input_address();
    method MemoryAddress output_address();
    method UInt#(32) pixels();

    //signal to outside world that filter is finished
    method Action finish(Bool finished);
    method Bool finished();
endinterface

module [ConfigCtx#(ConfigAddrWidth, ConfigDataWidth)] filterConfig(InternalConfig_ifc);

    FIFO#(Token) cfg_start <- mkSizedFIFO(1);
    Reg#(Bool) cfg_finished <- mkReg(True);

    Reg#(MemoryAddress) cfg_input_addr <- mkRegU;
    Reg#(MemoryAddress) cfg_output_addr <- mkRegU;

    Reg#(UInt#(32)) cfg_pixel_amount <- mkRegU;
    Reg#(PixelLayout) cfg_pixel_layout <- mkRegU;

    addFifoWO(offs_start, cfg_start);
    addRegRO(offs_finished, cfg_finished);
    addRegWO(offs_input_addr, cfg_input_addr);
    addRegWO(offs_output_addr, cfg_output_addr);
    addRegWO(offs_pixel_amount, cfg_pixel_amount);
    addRegWO(offs_pixel_layout, cfg_pixel_layout);

    interface start = toGet(cfg_start);
    method pixel_layout = cfg_pixel_layout._read;
    method input_address = cfg_input_addr._read;
    method output_address = cfg_output_addr._read;
    method pixels = cfg_pixel_amount._read;

    method finish = cfg_finished._write;
    method finished = cfg_finished._read;

endmodule

module [Module] mkNegativeFilter(Filter_ifc#(id_width, amountw))
    provisos(
        NumAlias#(addrw, MemoryAddrWidth),
        NumAlias#(dataw, AXIDataWidth),
        NumAlias#(pixels_per_xfer, TDiv#(AXIDataWidth, 8)) //we expect grayscale input pixels
    );

    //memory interface
    Axi4MasterRead#(addrw, dataw, id_width, 0, 24) mem_master_rd <- mkAxi4MasterRead(8, 8, True, 128, True, 8, True, True);
    Axi4MasterWrite#(addrw, dataw, id_width, 0, 24) mem_master_wr <- mkAxi4MasterWrite(8, 8, True, 128, True, 1, True, 2);

    //config instantiation
    IntExtConfig_ifc#(ConfigAddrWidth, ConfigDataWidth, InternalConfig_ifc) config_module <- axi4LiteConfigFromContext(filterConfig);
    AXI4LiteConfig_ifc#(ConfigAddrWidth, ConfigDataWidth) axi4config = config_module.bus_ifc;
    InternalConfig_ifc cfg = config_module.device_ifc;

    //internal control
    Reg#(Bool) running <- mkReg(False);
    Reg#(Bool) idle <- mkReg(False);
    Reg#(UInt#(32)) progress <- mkRegU;

    //processing fifos
    // FIFO#(Grayscale) input_fifo <- mkPipelineFIFO;
    FIFO#(Bit#(AXIDataWidth)) output_fifo <- mkBypassFIFO;


    rule rstart(!running && cfg.finished());

        //remove token from start fifo to kick off
        let token <- cfg.start.get();

        //now that start bit has been set, assume other config registers contain valid values
        MemoryAddress start_address = cfg.input_address();
        MemoryAddress output_address = cfg.output_address();

        UInt#(32) amount_bytes = 0;
        if(cfg.pixel_layout() == NORMAL)
            amount_bytes = cfg.pixels() * fromInteger(valueof(BytesPerWord)); 
        else if(cfg.pixel_layout() == PACKED) begin
            amount_bytes = cfg.pixels();
            printColorTimed(YELLOW, $format("Will transfer %0d bytes", amount_bytes));
        end
        
        running <= True;
        idle <= True;
        cfg.finish(False);

        let read_rq = AxiRequest {
            address: start_address,
            bytesToTransfer: truncate(amount_bytes),
            region: 0
        };
        let write_rq = AxiRequest {
            address: output_address,
            bytesToTransfer: truncate(amount_bytes),
            region: 0
        };

        //relay axi read and write requests to generic masters
        mem_master_rd.server.request.put(read_rq);
        mem_master_wr.request.put(write_rq);

        printColorTimed(YELLOW, $format("InputAddr: %0x, OutputAddr: %0x", start_address, output_address));
        printColorTimed(YELLOW, $format("Started filter"));
    endrule

    rule rwait_for_startup(mem_master_rd.active() && running && idle);
        idle <= False;
    endrule

    rule rreceive (running && !idle);
        (* split *)
        if(cfg.pixel_layout() == PACKED) begin
            Bit#(AXIDataWidth) packed_pixels <- mem_master_rd.server.response.get();

            Vector#(BytesPerXfer, Grayscale) pixels = unpack(packed_pixels);
            //actual operation
            pixels = map(negate, pixels);

            output_fifo.enq(pack(pixels));
        end else if (cfg.pixel_layout() == NORMAL) begin
            //Not implemented
        end
    endrule

    rule rout (running && !idle);
        //for first test write values as single word bursts to memory
        let out = output_fifo.first(); output_fifo.deq;
        mem_master_wr.data.put(out);
    endrule

    rule rfinish (running && !idle && !mem_master_rd.active() && !mem_master_wr.active());
        running <= False;
        cfg.finish(True);
    endrule
    

    interface fab_config_rd = axi4config.s_rd;
    interface fab_config_wr = axi4config.s_wr;

    interface fab_mem_rd = mem_master_rd.fab;
    interface fab_mem_wr = mem_master_wr.fab;

endmodule

endpackage