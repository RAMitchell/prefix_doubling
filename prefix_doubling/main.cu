
#include "cuda_runtime.h"
#include <stdio.h>
#include <stdint.h>
#include <iostream>

//Thrust includes
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sequence.h>
#include <thrust/sort.h>
#include <thrust/iterator/counting_iterator.h>

#include "cuda_helpers.cuh"

typedef uint8_t U8;
typedef uint32_t U32;

using namespace thrust;

void mark_head(thrust::device_vector<int>& keys, thrust::device_vector<int>& buckets){
	
	int *keys_r = raw(keys);
	int *bucket_r = raw(buckets);
	auto r = counting_iterator<int>(0);
	int n = keys.size();

	for_each(r, r + n, [=] __device__(int i) {
		//First item is always head
		if (i == 0){
			bucket_r[i] = 1;
		}
		//Is different than previous item - must be a bucket head
		else if (keys_r[i] != keys_r[i - 1]){
			bucket_r[i] = 1;
		}
		//Not a bucket head
		else{
			bucket_r[i] = 0;
		}
	});
}


void get_rank(thrust::device_vector<int>& buckets, thrust::device_vector<int>& rank, thrust::device_vector<int>& sa){

	//Scan bucket heads into keys. Keys just used as temporary storage
	inclusive_scan(buckets.begin(), buckets.end(), buckets.begin());
	
	//Calculate rank - stores rank inverse to the suffix array
	// e.g. rank[3] stores the bucket position of sa[?] = 3
	int *rank_r = raw(rank);
	int *sa_r = raw(sa);
	int *buckets_r = raw(buckets);

	auto r = counting_iterator<int>(0);
	int n = sa.size();

	for_each(r, r + n, [=] __device__(int i) {
		int suffix = sa_r[i];
		rank_r[suffix] = buckets_r[i];
	});
	
}

void get_sort_keys(thrust::device_vector<int>& keys, thrust::device_vector<int>& buckets, thrust::device_vector<int>& rank, thrust::device_vector<int>& sa, int step){

	int *rank_r = raw(rank);
	int *sa_r = raw(sa);
	int *keys_r = raw(keys);
	int *buckets_r = raw(buckets);

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

void sort_sa(thrust::device_vector<int>& keys, thrust::device_vector<int>& buckets, thrust::device_vector<int>& sa){
	
	stable_sort_by_key(keys.begin(), keys.end(), sa.begin());

	stable_sort_by_key(buckets.begin(), buckets.end(), sa.begin());

}

int suffix_array(const thrust::device_vector<U8>& data, thrust::device_vector<int>& sa){

	assert(data.size() == sa.size());

	int n = data.size();

	//Init suffix array
	sequence(sa.begin(), sa.end());

	device_vector<int> keys(n); //Sort keys
	device_vector<int> buckets(n, 0); //Bucket head flags
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
		get_rank(buckets, rank, sa);
		
		//Use rank as new sort keys
		get_sort_keys(keys, buckets, rank, sa, step);

		//Sort
		sort_sa(keys, buckets, sa);


		print("SA", sa);
		print("Keys", keys);
		print("Buckets", buckets);
		print("rank", rank);
		return 0;

		step *= 2;

		//Just in case, check for infinite loop
		if (step < 0){
			std::cout << "Error: Prefix doubling infinite loop.\n";
			return 1;
		}
	}
	
	return 0;
}


int main()
{
	const size_t n = 6;
	char test[] = "banana";

	device_vector<U8> data(test, test + n); //Input data
	device_vector<int> sa(n); //Suffix array
	
	suffix_array(data, sa);
	
    return 0;
}
