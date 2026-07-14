# ARM Cortex-M3 SoC Testbench

This repository contains the hardware logic, models, and testbenches for an ARM Cortex-M3 System-on-Chip (SoC). It includes a generic execution testbench with Makefile support for running multiple software tests (e.g., hello, memory_tests, dualtimer_demo, etc.) using simulators like Questa/ModelSim, VCS, or Xcelium.

## Prerequisites
- A supported Verilog simulator (Questa/ModelSim, Synopsys VCS, or Cadence Xcelium)
- GCC ARM cross-compiler (if compiling C tests from scratch)
- GNU Make

## Running the Tests
To easily run a test, you must first compile the C testcode in its respective folder, then compile the testbench, and finally run it.

### 1. Compile the C Testcode
Navigate to the testcode's folder and compile it. For example, for the `hello` test:
```bash
cd m3designstart/logical/testbench/testcodes/hello
make
```

### 2. Compile the Testbench
Navigate to the main execution testbench directory and compile the hardware environment:
```bash
cd ../../execution_tb
make compile
```

### 3. Run the Simulation
Run the test by passing its name to the `make run` command:
```bash
make run TESTNAME=hello
```





