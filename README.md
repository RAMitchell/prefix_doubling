#Prefix doubling suffix array sort

This repo contains an implementation of the manber myers prefix doubling sort in CUDA. 

It is used to create the suffix array of a given string. Suffix arrays may be used in data compression, genomic sequencing or text indexing. 

##Build
The project can be built "as-is" with visual studio 2013 community and CUDA toolkit 7.5 or greater. 

CUDA toolkit 7.5 is required due to the GPU lambda feature which makes the code more readable and concise. 

##Benchmarks
Benchmarks performed with an i7-4700MQ and Nvidia GT 740m with 2GB video memory.

The algorithm is tested up to sizes of 50MB on a 2GB card. You may find it runs out of memory at larger sizes.

For the CPU version I have used a simple O(nlog(n)) prefix doubling implementation available from http://codeforces.com/blog/entry/4025.

Test sizes are 10MB and 30MB and alphabet sizes are 4 (e.g. DNA), 26 and 256. Data is randomly generated. 

Note: Realistically you would not perform a suffix array sort on random data - it just provides a quick way of establishing basic performance characteristics.

Implementation  | Size (MB) | Alphabet size | Time (s)
--- | --- | --- | ---
CPU  | 10 | 4 | 62.70
GPU  | 10 | 4 | 14.61
CPU  | 10 | 26 | 9.45
GPU  | 10 | 26 | 1.35
CPU  | 10 | 256 | 7.66
GPU  | 10 | 256 | 0.75
CPU  | 30 | 4 | 240.31
GPU  | 30 | 4 | 40.57
CPU  | 30 | 26 | 35.97
GPU  | 30 | 26 | 3.99
CPU  | 30 | 256 | 30.26
GPU  | 30 | 256 | 2.27





