# bitonic_sorter
Bitonic sorter (Batcher's sorting network) written in Verilog, parameterizable and fully pipelined.
Two interfaces available: basic interface and AXI-Stream.

'bitonic_sort.v' is a top file with basic interface;
'axis_bitonic_sort.v' - is a top file with AXI-Stream interface.

## Specifications (for basic interface):
* Depth (latency): log2(CHAN_NUM)\*(log2(CHAN_NUM)+1)/2
* Comparators (count): CHAN_NUM\*log2(CHAN_NUM)\*(log2(CHAN_NUM)+1)/4
* Registers (count): CHAN_NUM\*log2(CHAN_NUM)\*(log2(CHAN_NUM)+1)\*DATA_WIDTH/2
* Number Formats: Signed Int, Unsigned Int
## Parameters:
* DATA_WIDTH - Data width of channel
* CHAN_NUM   - Number of channels
* DIR        - Sorted direction (0 - ascending, 1 - descending)
* SIGNED     - Signed or Unsigned (0 - unsigned, 1 - signed)
	
## Ports
### Basic
* clk      - Clock
* data_in  - Input data
* data_out - Output data
	
### AXI-Stream
* aclk          - Clock
* aresetn       - Synchronous reset (active-LOW)
* s_axis_tdata  - Input data
* s_axis_tvalid - Input 'Valid' signal
* s_axis_tready - Output 'Ready' signal
* s_axis_tlast  - Input 'Last' transfer signal (optional)
* m_axis_tdata  - Output data
* m_axis_tvalid - Output 'Valid' signal
* m_axis_tready - Input 'Ready' signal
* m_axis_tlast  - Output 'Last' transfer signal (optional)
	
### Data Format
* \*data\*[DATA_WIDTH\*1-1-:DATA_WIDTH] - Channel '0'
* \*data\*[DATA_WIDTH\*2-1-:DATA_WIDTH] - Channel '1'
* \*data\*[DATA_WIDTH\*3-1-:DATA_WIDTH] - Channel '2'
* ...
* \*data\*[DATA_WIDTH\*CHAN_NUM-1-:DATA_WIDTH] - Channel 'CHAN_NUM-1'

## Example
![Bitonic Sorter](/img/bitonic.gif)

## Release
Bitonic Sort IP Core for Xilinx 7-Series FPGAs (Vivado version >= 2018.3)