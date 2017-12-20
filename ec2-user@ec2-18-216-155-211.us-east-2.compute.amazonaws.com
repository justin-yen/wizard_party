import argparse
import copy
import random
from random import shuffle
import time


# def solve(num_wizards, num_constraints, wizards, constraints):
#     return sorted(wizards)

def best_start_constraint(constraints):
    wizard_count = {}
    for c in constraints:
        for i in range(3):
            if c[i] in wizard_count:
                wizard_count[c[i]] += 1
            else:
                wizard_count[c[i]] = 1
    max_constraint = {}
    for c in constraints:
        max_constraint[' '.join(c)] = wizard_count[c[0]]
        for i in range(1,3):
            max_constraint[' '.join(c)] = wizard_count[c[i]]
    inverse = [(value, key) for key, value in max_constraint.items()]
    #print(max(inverse)[1]).split(" ")
    return max(inverse)[1].split(" ")

def most_two_common_3(constraints):
    max_constraint_num = 0
    max_constraint = None
    for c in constraints:
        count = 0
        for c_2 in constraints:
            if c[0] == c_2[0] and c[1] == c_2[1] and c[2] != c_2[2]:
                count += 1
        if count > max_constraint_num:
            max_constraint = c
            max_constraint_num = count

    return max_constraint







def solve(num_wizards, num_constraints, wizards, constraints):
    #random_num = random.randint(0, len(constraints)-1)
    #current_clause = constraints[random_num]
    start_time = time.time()
    current_clause = most_two_common_3(constraints)
    if current_clause == None:
        current_clause = best_start_constraint(constraints)
    subproblems = possible_orders(current_clause)
    for subproblem in subproblems:
        result = solver(subproblem, constraints)
        if result:
            print(time.time()-start_time)
            return result
    return False


def solver(subproblem, constraints): #recursive function that returns the subproblem that satisfies constraints, False if none
    three_clauses = find_three_clauses(subproblem, constraints)
    new_constraints = copy.copy(constraints)
    for three_clause in three_clauses:
        if violates_clause(subproblem, three_clause):         
            return False
        del new_constraints[new_constraints.index(three_clause)]
    #new_constraints = [x for x in constraints if x not in three_clauses]
    if len(subproblem) == num_wizards:
        return subproblem
    possible_constraints = find_clauses_two_in_common_3(subproblem, constraints)
    constraint = None
    if possible_constraints != []:
        constraint = best_start_constraint(possible_constraints)

        #constraint = possible_constraints[random.randint(0, len(possible_constraints)-1)] # first clause where 2 seen wizards in common
    left_index, right_index = -1, -1
    if constraint:
        two_common_3 = True
        two_common_2 = False
    else:
        two_common_3 = False
        possible_constraints = find_clauses_two_in_common_2(subproblem, constraints)
        if possible_constraints != []:
            #constraint = possible_constraints[random.randint(0, len(possible_constraints)-1)]
            constraint = best_start_constraint(possible_constraints)
        if constraint:
            two_common_2 = True
        else:
            two_common_2 = False
            possible_constraints = find_clauses_one_in_common(subproblem, constraints)
            if possible_constraints != []:
                #constraint = possible_constraints[random.randint(0, len(possible_constraints)-1)]
                constraint = best_start_constraint(possible_constraints)
            if constraint:
                possible_constraints = find_clauses_with_zero(subproblem, constraints)
                if possible_constraints != []:
                    #constraint = possible_constraints[random.randint(0, len(possible_constraints)-1)]
                    constraint = best_start_constraint(possible_constraints)
    curr_wiz = None
    for wiz in constraint:
        if wiz not in subproblem:
            curr_wiz = wiz
        if wiz in subproblem:
            left_index = subproblem.index(wiz) 

    new_subproblems = []

    if two_common_3:
        # print("2_3 in common, constraint: " + str(constraint))
        curr_wiz = constraint[2] # generate subproblems, use a constraint with 3rd wizard that's not in current subproblem
        # find the indices of the interval (1st and 2nd wizards in constraint)
        if subproblem.index(constraint[0]) < subproblem.index(constraint[1]):
            left_index = subproblem.index(constraint[0])
            right_index = subproblem.index(constraint[1])
        else:
            left_index = subproblem.index(constraint[1])
            right_index = subproblem.index(constraint[0])
        for index in range(len(subproblem)+1):
            if not (left_index < index <= right_index):
                new_subproblem = list(subproblem)
                new_subproblem.insert(index, curr_wiz)
                new_subproblems.append(new_subproblem)
        del new_constraints[new_constraints.index(constraint)]
    elif two_common_2:
        print("2_2 in common, constraint: " + str(constraint))
        if constraint[0] in subproblem:
            if subproblem.index(constraint[0]) > subproblem.index(constraint[2]):
                for i in range(0, len(subproblem)):
                    if subproblem[i] == constraint[2]:
                        left_index = i + 1
                for i in range(left_index, len(subproblem)+1):
                    new_subproblem = list(subproblem)
                    new_subproblem.insert(i, curr_wiz)
                    new_subproblems.append(new_subproblem)
            else:
                for i in range(0, len(subproblem)):
                    if subproblem[i] == constraint[2]:
                        right_index = i
                for i in range(0,right_index+1):
                    new_subproblem = list(subproblem)
                    new_subproblem.insert(i, curr_wiz)
                    new_subproblems.append(new_subproblem)
        else:
            if subproblem.index(constraint[1]) > subproblem.index(constraint[2]):
                for i in range(0, len(subproblem)):
                    if subproblem[i] == constraint[2]:
                        left_index = i + 1
                for i in range(left_index, len(subproblem)+1):
                    new_subproblem = list(subproblem)
                    new_subproblem.insert(i, curr_wiz)
                    new_subproblems.append(new_subproblem)
            else:
                for i in range(0, len(subproblem)):
                    if subproblem[i] == constraint[2]:
                        right_index = i
                for i in range(0,right_index+1):
                    new_subproblem = list(subproblem)
                    new_subproblem.insert(i, curr_wiz)
                    new_subproblems.append(new_subproblem)
        del new_constraints[new_constraints.index(constraint)]

    else: #case where constraint only has 1 or 0 wizards in common w subproblem
        print("0 or 1 in common, constraint: " + str(constraint))
        for index in range(len(subproblem)+1):
            new_subproblem = list(subproblem)
            new_subproblem.insert(index, curr_wiz)
            new_subproblems.append(new_subproblem)
        del new_constraints[new_constraints.index(constraint)]
    random.shuffle(new_subproblems)
    for new_subproblem in new_subproblems:          # recursively searches down branches of each subproblem
        # print_violation_count(subproblem, constraints)
        result = solver(new_subproblem, new_constraints)
        if result:
            return result
    return False

def violates_clause(subproblem, clause):
    try:
        w1 = subproblem.index(clause[0])
        w2 = subproblem.index(clause[1])
        w3 = subproblem.index(clause[2])
        return (w2 > w3 > w1) or (w1 > w3 > w2)
    except ValueError:
        return True

def possible_orders(clause):
    return [[clause[0], clause[1], clause[2]], 
            [clause[1], clause[0], clause[2]],
            [clause[2], clause[0], clause[1]],
            [clause[2], clause[1], clause[0]]]

def find_three_clauses(subproblem, clauses):
    return_clauses = []
    for clause in clauses:
        if clause[0] in subproblem and clause[1] in subproblem and clause[2] in subproblem:
            return_clauses.append(clause)
    return return_clauses

def find_clauses_two_in_common_3(subproblem, clauses):
    to_return = []
    for clause in clauses:
        if clause[2] not in subproblem and clause[1] in subproblem and clause[0] in subproblem:
            to_return.append(clause)
    return to_return


def find_clause_two_in_common_3(subproblem, clauses):
    for clause in clauses:
        if clause[2] not in subproblem and clause[1] in subproblem and clause[0] in subproblem:
            return clause
    return None

def find_clauses_two_in_common_2(subproblem, clauses):
    to_return = []
    for clause in clauses:
        if clause[1] not in subproblem and clause[2] in subproblem and clause[0] in subproblem:
            to_return.append(clause)
        if clause[0] not in subproblem and clause[1] in subproblem and clause[2] in subproblem:
            to_return.append(clause)
    return to_return

def find_clause_two_in_common_2(subproblem, clauses):
    for clause in clauses:
        if clause[1] not in subproblem and clause[2] in subproblem and clause[0] in subproblem:
            return clause
        if clause[0] not in subproblem and clause[1] in subproblem and clause[2] in subproblem:
            return clause
    return None

def find_clauses_one_in_common(subproblem, clauses):
    to_return = []
    for clause in clauses:
        if clause[0] in subproblem and clause[1] not in subproblem and clause[2] not in subproblem:
            to_return.append(clause)
        if clause[1] in subproblem and clause[0] not in subproblem and clause[2] not in subproblem:
            to_return.append(clause)
        if clause[2] in subproblem and clause[0] not in subproblem and clause[1] not in subproblem:
            to_return.append(clause)
    return to_return

def find_clause_one_in_common(subproblem, clauses):
    for clause in clauses:
        if clause[0] in subproblem and clause[1] not in subproblem and clause[2] not in subproblem:
            return clause
        if clause[1] in subproblem and clause[0] not in subproblem and clause[2] not in subproblem:
            return clause
        if clause[2] in subproblem and clause[0] not in subproblem and clause[1] not in subproblem:
            return clause
    return None

def find_clauses_with_zero(subproblem, clauses):
    to_return = []
    for clause in clauses:
        no_common = True
        for i in range(len(clause)):
            if clause[i] in subproblem:
                no_common = False
        if no_common:
            to_return.append(clause)
    return to_return

def find_clause_with_zero(subproblem, clauses):
    for clause in clauses:
        no_common = True
        for i in range(len(clause)):
            if clause[i] in subproblem:
                no_common = False
        if no_common:
            return clause
    return None

def print_violation_count(subproblem, clauses):
    sum = 0
    for clause in clauses:
        if violates_clause(subproblem, clause):
            sum += 1
    print(sum)
    return

def read_input(filename):
    with open(filename) as f:
        num_wizards = int(f.readline())
        num_constraints = int(f.readline())
        constraints = []
        wizards = set()
        for _ in range(num_constraints):
            c = f.readline().split()
            constraints.append(c)
            for w in c:
                wizards.add(w)
                
    wizards = list(wizards)
    return num_wizards, num_constraints, wizards, constraints

def write_output(filename, solution):
    with open(filename, "w") as f:
        for wizard in solution:
            f.write("{0} ".format(wizard))


if __name__=="__main__":
    parser = argparse.ArgumentParser(description = "Constraint Solver.")
    parser.add_argument("input_file", type=str, help = "___.in")
    parser.add_argument("output_file", type=str, help = "___.out")
    args = parser.parse_args()

    num_wizards, num_constraints, wizards, constraints = read_input(args.input_file)
    solution = solve(num_wizards, num_constraints, wizards, constraints)
    write_output(args.output_file, solution)
    print(solution)

