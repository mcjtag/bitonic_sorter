# bitonic_sorter
Bitonic sorter (Batcher's sorting network) written in Verilog, parameterizable and fully pipelined.
A file 'bitonic_sort.v' is a top file.

## Specifications:
* Depth (latency in cycles): log2(CHAN_NUM) * (log2(CHAN_NUM) + 1) / 2
* Comparators (count): CHAN_NUM * log2(CHAN_NUM) * (log2(CHAN_NUM) + 1) / 4
* Registers (count): CHAN_NUM * log2(CHAN_NUM) * (log2(CHAN_NUM) + 1) * DATA_WIDTH / 2
