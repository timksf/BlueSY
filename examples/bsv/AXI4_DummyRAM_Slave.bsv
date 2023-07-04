package AXI4_DummyRAM_Slave;

//standard lib imports
import GetPut :: *;
import Vector :: *;

import AXI4_Types :: *;
import AXI4_Slave :: *;

//Third party imports
import BlueLib :: *;

//custom imports
import BDPIFunctions :: *;
import DummyRAM :: *;

typedef Bit#(32) Word;

interface AXI4DummyRAM_ifc#(numeric type sz, numeric type dataw);
    interface AXI4_Slave_Rd_Fab#(32, dataw, 1, 0) fab_rd;
    interface AXI4_Slave_Wr_Fab#(32, dataw, 1, 0) fab_wr;
    method UInt#(64) ram_instance();
endinterface

module mkAXI4DummyRAM#(Bool v)(AXI4DummyRAM_ifc#(sz, dataw))
    provisos(
        Mul#(32, words_per_request, dataw), //assert that dataw is multiple of 32 (word size)
        NumAlias#(32, wordw),
        NumAlias#(32, addrw),
        NumAlias#(1, id_width)
    );

    //one line instantiation is not readable
    AXI4_Slave_Rd#(addrw, dataw, 1, 0) slave_rd();
    mkAXI4_Slave_Rd#(8, 8) _internal_rd(slave_rd);

    AXI4_Slave_Wr#(addrw, dataw, 1, 0) slave_wr();
    mkAXI4_Slave_Wr#(8, 8, 8) _internal_wr(slave_wr);

    DummyRAMSimple_ifc m_backend <- mkDummyRAM_simple;
    Reg#(UInt#(64)) mem_ptr <- mkRegU;

    Reg#(Bit#(1)) cur_id <- mkRegU;
    Reg#(UInt#(9)) transfers_left <- mkReg(0);
    Reg#(Bit#(addrw)) cur_addr <- mkRegU;
    PulseWire do_resp <- mkPulseWire;

    Reg#(Bool) init <- mkReg(False);

    //rule to initialize c++ memory model
    rule rinit (!init);
        let ptr <- create_DummyRAM(fromInteger(valueof(sz)));
        m_backend.set_ram(ptr);
        init <= True;
    endrule

    rule rprocess_rd_rq (transfers_left == 0 && init);
        let rrq <- slave_rd.request.get();
        cur_id <= rrq.id;
        transfers_left <= extend(rrq.burst_length) + 1;
        cur_addr <= rrq.addr >> 2; //convert from byte address to word address

        UInt#(32) bytes_in_transfer = fromInteger(valueof(TDiv#(dataw, 8))) * (extend(rrq.burst_length) + 1);
        //maybe only allow burst sizes of B4, since memory model can only
        //respond with whole 32 bitwords
        if(v)
            printColorTimed(YELLOW, $format("Incoming Read Request for %h, bytes: ", rrq.addr, bytes_in_transfer));
    endrule

    rule rprocess_rd_burst (transfers_left != 0 && init);
        transfers_left <= transfers_left - 1;

        cur_addr <= cur_addr + fromInteger(valueof(words_per_request));
        // if(v)
        //     printColorTimed(YELLOW, $format("Handling Read Burst, left: %d", transfers_left));
        Vector#(words_per_request, Word) from_memory = newVector;

        for(Integer i = 0; i < valueof(words_per_request); i = i + 1) begin
            let v <- m_backend.read(unpack(extend(cur_addr)) + fromInteger(i));
            Word w = pack(v);
            from_memory[i] = w;
        end

        slave_rd.response.put(AXI4_Read_Rs { id: cur_id, data: pack(from_memory), resp: OKAY, last: (transfers_left == 1), user: 0});
    endrule

    Reg#(UInt#(9))          transfers_left_write <- mkReg(0);
    Reg#(Bit#(addrw))       cur_addrw <- mkRegU;  
    Reg#(Bit#(id_width))    cur_id_write <- mkRegU;

    //data appears at least one cycle later?, otherwise use CReg for cur_addrw and cur_id_write
    rule rprocess_wr_rq (transfers_left_write == 0 && init);
        let wrq_addr <- slave_wr.request_addr.get();
        transfers_left_write <= extend(wrq_addr.burst_length) + 1;
        //maybe only support INCR burst type

        UInt#(32) bytes_in_transfer = fromInteger(valueof(TDiv#(dataw, 8))) * (extend(wrq_addr.burst_length) + 1);

        cur_id_write <= wrq_addr.id;
        cur_addrw <= wrq_addr.addr >> 2; //byte addr. -> word addr.
        if(v)
            printColorTimed(YELLOW, $format("Incoming Write Request for: %h, bytes: %d", wrq_addr.addr >> 2, bytes_in_transfer));
    endrule

    rule rprocess_wr_burst (transfers_left_write != 0 && init);
        transfers_left_write <= transfers_left_write - 1;
        cur_addrw <= cur_addrw + fromInteger(valueof(words_per_request));

        let wrq_data <- slave_wr.request_data.get;
        Vector#(words_per_request, Bit#(32)) words = unpack(wrq_data.data);

        // if(v) begin
        //     printColorTimed(YELLOW, $format("Handling Write Burst, left: %d", transfers_left_write));
        //     // $display("%b", wrq_data.data);
        // end

        //strobe of only 1s -> full bus is valid
        for(Integer i = 0; i < valueof(words_per_request); i = i + 1) begin
            // $display("writing %h to %h with strobe %b", words[i], cur_addrw + fromInteger(i), wrq_data.strb);
            Integer bytes_per_word = valueof(TDiv#(wordw, 8));
            Integer word_idx = i * bytes_per_word;
            Bit#(TDiv#(wordw, 8)) curr_strb = wrq_data.strb[word_idx+bytes_per_word-1:word_idx]; //strobe is byte based
            if(curr_strb == unpack(-1)) 
                m_backend.write(unpack(cur_addrw) + fromInteger(i), unpack(words[i]));
            else begin
                //write anyways
                 m_backend.write(unpack(cur_addrw) + fromInteger(i), unpack(words[i]));
                 //but notify
                printColorTimed(RED, $format("INFO: Strobe only valid for partial word: %b (was the input amount divisible by word length?)", curr_strb));
            end
        end

        if(transfers_left_write == 1)
            slave_wr.response.put(AXI4_Write_Rs { id: cur_id_write, resp: OKAY, user: 0 });
    endrule

    method ram_instance = m_backend.get_ram;

    interface fab_rd = slave_rd.fab;
    interface fab_wr = slave_wr.fab;

endmodule

endpackage