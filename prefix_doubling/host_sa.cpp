#include <vector>
#include <algorithm>

#define REP(i, n) for (int i = 0; i < (int)(n); ++i)

bool sufCmp(int i, int j, std::vector<int> &pos, int n, int gap)
{
	if (pos[i] != pos[j])
		return pos[i] < pos[j];
	i += gap;
	j += gap;
	return (i < n && j < n) ? pos[i] < pos[j] : i > j;
}

void host_sa(const unsigned char * S, int * sa, int n)
{
	std::vector<int> pos(n);
	std::vector<int> tmp(n);

	REP(i, n) sa[i] = i, pos[i] = S[i];
	for (int gap = 1;; gap *= 2)
	{
		std::sort(sa, sa + n, [&pos, gap, n](int i, int j) -> bool
		{
			if (pos[i] != pos[j])
				return pos[i] < pos[j];
			i += gap;
			j += gap;
			return (i < n && j < n) ? pos[i] < pos[j] : i > j;
		});

		REP(i, n - 1) tmp[i + 1] = tmp[i] + sufCmp(sa[i], sa[i + 1], pos, n, gap);
		REP(i, n) pos[sa[i]] = tmp[i];
		if (tmp[n - 1] == n - 1) break;
	}
}
