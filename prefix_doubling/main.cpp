#include <stdio.h>
#include <stdint.h>
#include <iostream>
#include <vector>
#include <algorithm>

#include "sa.cuh"
#include "sa.h"

using namespace std;

template <typename T>
void print(char *label, const vector<T>& v)
{
	std::cout << label << ":\n";
	for (auto elem : v)
		std::cout << " " << (int)elem;
	std::cout << "\n";
}

void test_sa(int n){
		
	std::cout << "Testing size: " << n << std::endl;

	vector<unsigned char> data(n);

	//Generate random data with an alphabet size of 5
	generate(data.begin(), data.end(), []() { return rand() % 5; });

	vector<int> sa(n);

	suffix_array(data.data(), sa.data(), n);

	vector<int> cpu_sa(n); 
	
	//Get reference suffix array
	cpuSA((const unsigned char*)data.data(), cpu_sa.data(), n);

	//Compare
	if (sa == cpu_sa){
		std::cout << "Success. SA is correct.\n";
	}
	else{
		std::cout << "Error. SA is incorrect.\n";
	}
}

int main()
{
	int sizes[] = { 1, 5, 30, 100, 1000, 100000, 1000000, 10000000 };
	srand(0);

	for (auto n : sizes){
		test_sa(n);
	}

    return 0;
}
