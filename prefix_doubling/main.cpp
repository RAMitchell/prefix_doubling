#include <stdio.h>
#include <stdint.h>
#include <iostream>
#include <vector>
#include <algorithm>
#include <time.h> 

#include "sa.cuh"
#include "sa.h"

using namespace std;

struct Timer{
	size_t start;
	Timer(){
		reset();
	}
	void reset(){
		start = clock();
	}
	double elapsed(){
		return ((double)clock() - start) / CLOCKS_PER_SEC;
	}
	void printElapsed(char * label){
		cout << label << ": " << elapsed() << "s\n";
	}
};


template <typename T>
void print(char *label, const vector<T>& v)
{
	std::cout << label << ":\n";
	for (auto elem : v)
		std::cout << " " << (int)elem;
	std::cout << "\n";
}

void test_sa(int n, int mod){
		
	std::cout << "Testing size " << n << ", mod " << mod << std::endl;

	vector<unsigned char> data(n);

	//Generate random data with an alphabet size of 5
	generate(data.begin(), data.end(), [mod]() { return rand() % mod; });

	vector<int> sa(n);
	
	Timer t;
	suffix_array(data.data(), sa.data(), n);
	t.printElapsed("Cuda suffix array");

	vector<int> cpu_sa(n); 
	
	t.reset();
	//Get reference suffix array
	cpuSA((const unsigned char*)data.data(), cpu_sa.data(), n);
	t.printElapsed("CPU suffix array");

	//Compare
	if (sa == cpu_sa)
		cout << "Success. SA is correct.\n";
	else
		cout << "Error. SA is incorrect.\n";
}

int main()
{
	//Size and alphabet size to test
	int sizes[] = { 100000, 1000000, 10000000};
	int mod[] = { 1, 26, 255 };
	srand(0);

	for (auto n : sizes)
		for (auto m : mod)
			test_sa(n, m);

    return 0;
}
