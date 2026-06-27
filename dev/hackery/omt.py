#!/usr/bin/env python3

class MinimalOMT:
    def __init__(self, num_vars, clauses, weights):
        self.num_vars = num_vars
        self.clauses = clauses      # The Logic (SAT)
        self.weights = weights      # The Theory (Costs)
        
        self.best_cost = float('inf')
        self.best_assignment = None
        self.search_steps = 0

    def bcp(self, assignment):
        """The SAT Engine: Pure Boolean Constraint Propagation (Deduction)"""
        assignment = assignment.copy()
        while True:
            changed = False
            for clause in self.clauses:
                unassigned_lits = []
                is_sat = False
                
                for lit in clause:
                    var, val = abs(lit), lit > 0
                    if var in assignment:
                        if assignment[var] == val:
                            is_sat = True
                            break
                    else:
                        unassigned_lits.append(lit)
                
                if is_sat:
                    continue
                if len(unassigned_lits) == 0:
                    return None  # LOGICAL CONFLICT: A clause was violated
                if len(unassigned_lits) == 1:
                    # Deduce the forced bit
                    forced_lit = unassigned_lits[0]
                    assignment[abs(forced_lit)] = (forced_lit > 0)
                    changed = True
                    
            if not changed:
                break
        return assignment

    def theory_check(self, assignment):
        """The Theory Engine: Evaluates the objective function (Optimization)"""
        # Calculate the lower bound cost of the CURRENT partial assignment
        current_cost = sum(self.weights[v] for v, val in assignment.items() if val)
        
        # If our partial cost is already worse than the best known solution,
        # we raise a THEORY CONFLICT to prune the search space.
        if current_cost >= self.best_cost:
            return False, current_cost
            
        return True, current_cost

    def solve(self):
        print("Starting OMT Search...")
        self._search({})
        print(f"\nSearch Complete in {self.search_steps} steps.")
        return self.best_assignment, self.best_cost

    def _search(self, current_assignment):
        self.search_steps += 1
        
        # 1. DEDUCTION: Let the SAT engine propagate logical constraints
        assignment = self.bcp(current_assignment)
        if assignment is None:
            return # Pruned by Logic
            
        # 2. OPTIMIZATION: Let the Theory engine check the math
        theory_ok, current_cost = self.theory_check(assignment)
        if not theory_ok:
            return # Pruned by Theory (Branch and Bound)
            
        # 3. SOLUTION FOUND: Did we assign all variables?
        if len(assignment) == self.num_vars:
            # We found a valid program that is CHEAPER than best_cost!
            self.best_cost = current_cost
            self.best_assignment = assignment
            print(f"[*] Found new optimum! Cost: {current_cost} | Assignment: {self.format_ast(assignment)}")
            return
            
        # 4. SEARCH: Pick an unassigned variable and branch
        unassigned = [v for v in range(1, self.num_vars + 1) if v not in assignment]
        var = unassigned[0]
        
        # Heuristic: Try False (Cost=0) before True (Cost>0) to find cheap solutions faster
        for val in [False, True]:
            next_assignment = assignment.copy()
            next_assignment[var] = val
            self._search(next_assignment)

    def format_ast(self, assignment):
        return [f"Instr_{v}" for v in range(1, self.num_vars + 1) if assignment.get(v, False)]


# ==========================================
# TEST CASE: Superoptimizing a Program
# ==========================================
# We want to synthesize a program using 4 possible instructions.
# 1: BitShift, 2: Add, 3: Multiply, 4: Branch
num_vars = 4

# The Theory: CPU Cycle costs for each instruction
weights = {
    1: 1,   # BitShift is very cheap (1 cycle)
    2: 2,   # Add is cheap (2 cycles)
    3: 10,  # Multiply is expensive (10 cycles)
    4: 15   # Branch is very expensive (15 cycles)
}

# The Logic: The constraints required to satisfy the user's specification
clauses = [
    [1, 3],       # Constraint 1: Program MUST use either BitShift OR Multiply
    [2, 4],       # Constraint 2: Program MUST use either Add OR Branch
    [-2, 1],      # Constraint 3: If you use Add, you MUST use BitShift
    [-3, 4],      # Constraint 4: If you use Multiply, you MUST use Branch
]

solver = MinimalOMT(num_vars, clauses, weights)
best_prog, best_cost = solver.solve()

print(f"\nFINAL SYNTHESIZED PROGRAM:")
print(f"Instructions: {solver.format_ast(best_prog)}")
print(f"Total CPU Cycles: {best_cost}")
