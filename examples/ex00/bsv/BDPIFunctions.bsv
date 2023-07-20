package BDPIFunctions;

//create function has to be !!ActionValue!!, otherwise it might get inlined everywhere, which is very bad
import "BDPI" function ActionValue#(UInt#(64)) create_DummyRAM(UInt#(32) sz);
import "BDPI" function ActionValue#(UInt#(64)) read_word_DummyRAM(
    UInt#(64) ptr,
    UInt#(64) addr
);
import "BDPI" function Action write_word_DummyRAM(
    UInt#(64) ptr,
    UInt#(64) addr,
    UInt#(64) data
);

//Image Loader; from file to memory to dummy ram model
import "BDPI" function ActionValue#(UInt#(64)) create_ImageLoader(String filename);
import "BDPI" function ActionValue#(UInt#(8)) get_pixel_ImageLoader(UInt#(64) ptr);

import "BDPI" function Action write_to_mem_seq_ImageLoader(
    UInt#(64) ptr,
    UInt#(64) ram_ptr,
    UInt#(64) start_addr
);

import "BDPI" function Action write_to_mem_interleaved_ImageLoader(
    UInt#(64) ptr,
    UInt#(64) ram_ptr,
    UInt#(64) start_addr
);

import "BDPI" function Action write_to_mem_gray_packed_ImageLoader(
    UInt#(64) ptr,
    UInt#(64) ram_ptr,
    UInt#(64) start_addr
);

//ImageWriter; from dummy ram model to file
import "BDPI" function Action mem_to_file_seq_ImageWriter(  
    UInt#(64) ram_ptr,
    UInt#(32) width,
    UInt#(32) height,
    String filename,
    UInt#(64) start_addr
);

//ImageWriter; from dummy ram model to file
import "BDPI" function Action mem_to_file_gray_ImageWriter(  
    UInt#(64) ram_ptr,
    UInt#(32) width,
    UInt#(32) height,
    String filename,
    UInt#(64) start_addr
);


import "BDPI" function Action mem_to_file_interleaved_ImageWriter(  
    UInt#(64) ram_ptr,
    UInt#(32) width,
    UInt#(32) height,
    String filename,
    UInt#(64) start_addr
);

import "BDPI" function Action mem_to_file_gray_packed_ImageWriter(  
    UInt#(64) ram_ptr,
    UInt#(32) width,
    UInt#(32) height,
    String filename,
    UInt#(64) start_addr
);

//ImageWriterStream: from values to image file
import "BDPI" function ActionValue#(UInt#(64)) create_ImageWriterStream(
    String filename,
    UInt#(32) width,
    UInt#(32) height
);

import "BDPI" function Action put_r_ImageWriterStream(
    UInt#(64) ptr,
    UInt#(8) pixel,
    Bool incr
);

import "BDPI" function Action put_g_ImageWriterStream(
    UInt#(64) ptr,
    UInt#(8) pixel,
    Bool incr
);

import "BDPI" function Action put_b_ImageWriterStream(
    UInt#(64) ptr,
    UInt#(8) pixel,
    Bool incr
);

endpackage