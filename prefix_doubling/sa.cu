#include "cuda_runtime.h"
#include <stdint.h>
#include <iostream>

//Thrust includes
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sequence.h>
#include <thrust/sort.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/execution_policy.h>

#include "cuda_helpers.cuh"

typedef uint8_t U8;
typedef uint32_t U32;

using namespace thrust;

void mark_head(device_vector<int>& keys, device_vector<U8>& buckets){

	int *keys_r = raw(keys);
	U8 *bucket_r = raw(buckets);
	auto r = counting_iterator<int>(0);
	int n = keys.size();

	for_each(r, r + n, [=] __device__(int i) {
		//Already marked - don't need to do anything
		if (bucket_r[i] == 1){
			return;
		}
		//First item is always head
		else if (i == 0){
			bucket_r[i] = 1;
		}
		//Is different than previous item - must be a bucket head
		else if (keys_r[i] != keys_r[i - 1]){
			bucket_r[i] = 1;
		}

	});
}


void get_rank(device_vector<U8>& buckets, device_vector<int>& b_scan, device_vector<int>& rank, device_vector<int>& sa){

	//Scan bucket heads
	inclusive_scan(buckets.begin(), buckets.end(), b_scan.begin());

	//Calculate rank - stores rank inverse to the suffix array
	// e.g. rank[3] stores the bucket position of sa[?] = 3
	int *rank_r = raw(rank);
	int *sa_r = raw(sa);
	int *b_scan_r = raw(b_scan);

	auto r = counting_iterator<int>(0);
	int n = sa.size();

	for_each(r, r + n, [=] __device__(int i) {
		int suffix = sa_r[i];
		rank_r[suffix] = b_scan_r[i];
	});

}

void get_sort_keys(device_vector<int>& keys, device_vector<int>& rank, device_vector<int>& sa, int step){

	int *rank_r = raw(rank);
	int *sa_r = raw(sa);
	int *keys_r = raw(keys);

	auto r = counting_iterator<int>(0);
	int n = keys.size();

	for_each(r, r + n, [=] __device__(int i) {
		//TODO: check if already sorted

		int next_suffix = sa_r[i] + step;
		//Went of end of string - must be lexicographically less than rest of bucket
		if (next_suffix >= n){
			//TODO: can this just be -1?
			keys_r[i] = -next_suffix;
		}
		//Else set sort key to rank of next suffix
		else{
			keys_r[i] = rank_r[next_suffix];
		}
	});


}

void sort_sa(device_vector<int>& keys, device_vector<int>& b_scan, device_vector<int>& sa){

	stable_sort_by_key(keys.begin(), keys.end(), make_zip_iterator(make_tuple(sa.begin(), b_scan.begin())));

	stable_sort_by_key(b_scan.begin(), b_scan.end(), make_zip_iterator(make_tuple(sa.begin(), keys.begin())));

}

int suffix_array(const unsigned char *data_in, int *sa_in, int n){
	
	try{

		//Copy up to device vectors
		device_vector<U8> data(data_in, data_in + n);
		device_vector<int> sa(n);

		//Init suffix array
		sequence(sa.begin(), sa.end());

		device_vector<int> keys(n); //Sort keys
		device_vector<U8> buckets(n, 0); //Bucket head flags
		device_vector<int> b_scan(n); //Scanned head flags
		device_vector<int> rank(n); //Rank of suffixes

		copy(data.begin(), data.end(), keys.begin());

		//Radix sort data and SA
		stable_sort_by_key(keys.begin(), keys.end(), sa.begin());

		int step = 1;
		//Begin prefix doubling loop - runs at most log(n) times
		while (true){

			//Mark bucket heads
			mark_head(keys, buckets);

			//Check if we are done, i.e. every item is a bucket head
			int result = reduce(buckets.begin(), buckets.end(), INT_MAX, minimum<int>());
			if (result == 1) break;

			//Get rank of suffixes
			get_rank(buckets, b_scan, rank, sa);

			//Use rank as new sort keys
			get_sort_keys(keys, rank, sa, step);

			//Sort
			sort_sa(keys, b_scan, sa);

			/*
			std::cout << "-----\n";
			print("SA", sa);
			print("Keys", keys);
			print("Buckets", buckets);
			print("rank", rank);
			std::cout << "-----\n";
			*/

			step *= 2;


			//Just in case, check for infinite loop
			if (step < 0){
				std::cout << "Error: Prefix doubling infinite loop.\n";
				return 1;
			}
		}

		//std::cout << "-----\n";
		//print("SA", sa);

		//Copy SA back to host
		safe_cuda(cudaMemcpy(sa_in, raw(sa), sizeof(int)*sa.size(), cudaMemcpyDeviceToHost));
	}
	catch (thrust::system_error &e)
	{
		std::cerr << "CUDA error: " << e.what() << std::endl;
	}

	return 0;
}