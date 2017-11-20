
def solve(num_wizards, num_constraints, wizards, constraints): 
	constraints_copy = constraints.copy()                   # copy of constraints since we'll be reducing
    order = []                                              # the working order to be returned
	constraints_by_key = {}
	for i in range(constraints):
		already_added = False
			for j in range(3):
				if constraints[i][j] in constraints_by_key:
					if (!already_added):
						constraints_by_key[constraints[i][j]] += constraints[i]
						already_added = True
					else:
						constraints_by_key[constraints[i]] = constraints[i]
						already_added = True
    while constraints_copy:
		random_num = random.randint(0, len(constraints_copy)-1)
        current_clause = constraints_copy[random_num]
        subproblems = [[current_clause[0], current_clause[1], current_clause[2]],
            [current_clause[1], current_clause[0], current_clause[2]],
            [current_clause[2], current_clause[0], current_clause[1]],
            [current_clause[2], current_clause[1], current_clause[0]]]
		for subproblem in subproblems:
			result = solver(subproblem, constraints_by_key)
			if result != False:
				return result
		return False

def solver(ordering, constraints_by_key): #recursive function that returns the ordering that satisfies constraints, False if none
	for wizard in ordering: #checking all constraints for each wizard present in the ordering
		for constraint in constraints_by_key[wizard]:
			if all 3 wizards in constraint are in ordering list:
				if constraint is not satisfied:  #don't explore this ordering since it violates a constraint
					return False
				else:
					remove this constraint from constraints_by_key
	generate constraint - heuristic: wizard that has least num of constraints? 
	curr_wiz = constraint[2] #generate subproblems, use a constraint with 3rd wizard that's not in current ordering
	left_index, right_index = -1, -1 	#find the indices of the interval (1st and 2nd wizards in constraint)
	for i in range(len(ordering)):			
		if ordering[i] == constraint[0] or ordering[1] == constriant[1]:
			if left_index != -1:
				left_index = i
			else:
				right_index = i
				break
	subproblems = []
	index = 0
	while index < len(range(ordering)):		#find possible placements for this wizard, which is anywhere not in the interval given by constraint
		new_ordering = list(ordering)
		new_ordering.insert(index, curr_wiz)
		subproblems.append(new_ordering)	#adds new ordering to list of subproblems
		if index + 1 > left_index:
			index = right_index + 1
		else:
			index += 1
	for subproblem in subproblems: 			#recursively searches down branches of each subproblem
		result = solver(subproblem, constraints_by_key)
		if result != False
			return result
	return False

