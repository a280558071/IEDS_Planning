# IEDS_Planning
 Integrated Energy Distribution System (IEDS) Planning method, include a matlab version *IEDS_planning.m* and a Python version *IEDS_planning.ipynb*
# Must-include package
 - For *IEDS_planning.ipynb*: **PuLP** see (https://coin-or.github.io/pulp/) (Python 3.7)
 - For *IEDS_planning.m*: **YALMIP** see (https://yalmip.github.io/)
 - Both files are calling GUROBI(https://www.gurobi.com/) to solve the problem, but could call other solvers as well. (see what solvers they support in abovementioned link).
# Some unknown issue
 - Even though IEDS_planning.ipynb is basicly a Python version of IEDS_planning.m, still don't know why their produced planning results are not the same.
 - Maybe lpSum() in PuLP don't support double for-loop?
# What you can learn
 - By reviewing these two files, you could see PuLP and YALMIP, even Python and MATLAB have a lot similar features in terms of programming.
 - How to realize an IEDS planning, by a deterministic planning model, see [1] for more details.
# To be updated
 - Robust planning for IEDS
# Ref
[1] 沈欣炜, 郭庆来, 许银亮 & 孙宏斌 (2019), 考虑多能负荷不确定性的区域综合能源系统鲁棒规划, 电力系统自动化, Vol. 43 No. 07, pp. 34-41.
