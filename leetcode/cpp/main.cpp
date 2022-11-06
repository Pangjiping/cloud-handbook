#include<iostream>
#include<vector>

using namespace std;

class Solution_nSum {
    // n数之和
    vector<vector<int>> nSumTarget(vector<int>&nums, int n, int start, int target)
    {
        int sz=nums.size();
        vector<vector<int>> res;

        // 至少应该是twoSum，并且数组大小不能小于n
        if (n<2 || sz < n) return res;

        // twoSum is basecase
        if (n==2)
        {
            int lo=start,hi=sz-1;
            while(lo<hi)
            {
                int left=nums[lo];
                int right=nums[hi];
                int sum=left+right;
                if (sum>target)
                {
                    while(lo<hi&&nums[hi]==right) hi--;
                }
                else if (sum<target)
                {
                    while(lo<hi&&nums[lo]==left) lo++;
                }
                else
                {
                    res.push_back({left,right});
                    while(lo<hi&&nums[lo]==left) lo++;
                    while(lo<hi&&nums[hi]==right) hi--;
                }
                            
            }
        }
        else
        {
            for (int i=start;i<sz;i++)
            {
                vector<vector<int>> subs=nSumTarget(nums,n-1,i+1,target-nums[i]);
                for (auto sub:subs)
                {
                    sub.push_back(nums[i]);
                    res.push_back(sub);
                }
                while(i<sz-1&&nums[i]==nums[i+1]) i++;
            }
        }
        return res;
    }
public:
    vector<vector<int>> fourSum(vector<int>& nums, int target) {
        sort(nums.begin(),nums.end());
        return nSumTarget(nums,4,0,target);
    }
};

int main()
{
    
    return 0;
}