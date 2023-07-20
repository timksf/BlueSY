package Testbench;

import StmtFSM :: *;

import BlueLib :: *;

import "BDPI" function Action display_ImageDisplay(String filename);

module mkTestbench();

    Stmt s = seq
        printColorTimed(BLUE, $format("Started simulation"));
        display_ImageDisplay("../../test.jpg");
        printColorTimed(BLUE, $format("Finished image display"));
    endseq;

    mkAutoFSM(s);

endmodule

endpackage