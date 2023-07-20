# ex00
This example has two main applications:
- test of the simple RAM model
- basic image filter using the RAM model
  
To build just got to `ex00/bsv` and type `make sim NAME=TestAXI4DummyRAM` or `make sim NAME=FilterTest` respectively.
The former reads a RGB image into the dummy RAM and then uses an AXI adapter to read the image and write it to another location in the RAM before writing the resulting image to a file.

The latter reads a grayscale image into the dummy RAM, configures the filter and then runs the filter. When the filter has finished (it inverts the image), a function imported from C++ will read the result from the RAM
model and write it to an output file.

# ex01
This example is rather small but shows that one can easily do more "exotic" stuff in BSV. 
To build just got to `ex01/bsv` and run `make sim`. This will display an image from within a bluesim simulation.
