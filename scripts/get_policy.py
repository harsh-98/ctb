import itertools
import sys

num=int(sys.argv[1])
msp = "'Org%dMSP.peer'"
orgs = [msp % i for i in range(1,num+1)]
combinations = itertools.combinations(orgs, num - num//2)

and_conditions = ["AND(%s)" % ", ".join(combination) for combination in combinations]
or_condition = '"OR(%s)"' % ", ".join(and_conditions)
print(or_condition)