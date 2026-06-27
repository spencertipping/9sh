#!/usr/bin/env python3

import random

class SAT_1UIP_MCTS:
    def __init__(self, formula, num_vars):
        self.formula = formula
        self.num_vars = num_vars
        
        # Refactored state for O(1) Implication Graph traversal
        self.assignment = {}      # var -> bool
        self.var_level = {}       # var -> decision level
        self.var_reason = {}      # var -> clause that forced this assignment (None if guessed)
        self.trail = []           # Stack of variables in the order they were assigned
        self.level = 0

    def assign(self, var, val, level, reason):
        """Helper to cleanly update all state trackers."""
        self.assignment[var] = val
        self.var_level[var] = level
        self.var_reason[var] = reason
        self.trail.append(var)

    def evaluate_clause(self, clause, test_assignment):
        unassigned = 0
        for lit in clause:
            var, val = abs(lit), lit > 0
            if var in test_assignment:
                if test_assignment[var] == val:
                    return True  # Satisfied
            else:
                unassigned += 1
        return False if unassigned == 0 else None

    def bcp(self):
        """Boolean Constraint Propagation (Builds the Implication Graph)"""
        changed = True
        while changed:
            changed = False
            for clause in self.formula:
                status = self.evaluate_clause(clause, self.assignment)
                if status is False:
                    return clause  # Conflict!
                
                unassigned_lits = [l for l in clause if abs(l) not in self.assignment]
                if status is None and len(unassigned_lits) == 1:
                    unit_lit = unassigned_lits[0]
                    var, val = abs(unit_lit), unit_lit > 0
                    
                    # The clause is the 'reason' this variable was forced
                    self.assign(var, val, self.level, clause)
                    changed = True
        return None

    # ==========================================
    # 1UIP CONFLICT ANALYSIS (The Surgical Compression)
    # ==========================================
    def analyze_conflict_1uip(self, conflict_clause):
        # Start with the literals in the conflict clause
        learned = set(conflict_clause)
        
        # Count how many literals in our learned clause are from the CURRENT level.
        # We want to reduce this number to exactly 1 (The First Unique Implication Point).
        path_c = sum(1 for lit in learned if self.var_level[abs(lit)] == self.level)
        
        trail_idx = len(self.trail) - 1
        
        # Walk backwards through the trail (reverse topological sort of implication graph)
        while path_c > 1:
            var = self.trail[trail_idx]
            trail_idx -= 1
            
            # Check if this variable is part of our current learned clause
            lit_in_learned = var if var in learned else (-var if -var in learned else None)
            
            if lit_in_learned is not None and self.var_level[var] == self.level:
                path_c -= 1
                learned.remove(lit_in_learned)
                
                reason_clause = self.var_reason[var]
                assert reason_clause is not None, "Hit a decision variable before finding 1UIP!"
                
                # Resolve the reason clause into our learned clause
                for reason_lit in reason_clause:
                    if abs(reason_lit) != var and reason_lit not in learned:
                        learned.add(reason_lit)
                        # If the new literal is from the current level, track it
                        if self.var_level[abs(reason_lit)] == self.level:
                            path_c += 1
                            
        learned_clause = list(learned)
        
        # Find backjump level: the highest decision level in the learned clause 
        # EXCLUDING the current level.
        levels = [self.var_level[abs(lit)] for lit in learned_clause if self.var_level[abs(lit)] != self.level]
        backjump_level = max(levels) if levels else 0
        
        return learned_clause, backjump_level

    def backjump(self, target_level):
        """Erase state back to the target level."""
        while self.trail and self.var_level[self.trail[-1]] > target_level:
            var = self.trail.pop()
            del self.assignment[var]
            del self.var_level[var]
            del self.var_reason[var]
        self.level = target_level

    # ==========================================
    # MCTS HEURISTIC (Unchanged from previous)
    # ==========================================
    def mcts_branching(self, iterations=30):
        unassigned = [v for v in range(1, self.num_vars + 1) if v not in self.assignment]
        if not unassigned: return None, None
        
        stats = {(v, val): [0, 0] for v in unassigned for val in [True, False]}
        
        for _ in range(iterations):
            test_var = random.choice(unassigned)
            test_val = random.choice([True, False])
            
            sim_assign = self.assignment.copy()
            sim_assign[test_var] = test_val
            for v in unassigned:
                if v != test_var: sim_assign[v] = random.choice([True, False])
                
            success = all(self.evaluate_clause(c, sim_assign) is not False for c in self.formula)
            
            stats[(test_var, test_val)][1] += 1
            if success: stats[(test_var, test_val)][0] += 1
                
        best_move = max(stats.keys(), key=lambda k: stats[k][0] / stats[k][1] if stats[k][1] > 0 else -1)
        return best_move

    def solve(self):
        while len(self.assignment) < self.num_vars:
            conflict_clause = self.bcp()
            
            if conflict_clause:
                if self.level == 0:
                    return False # UNSAT
                
                # 1UIP Analysis
                learned_clause, backjump_level = self.analyze_conflict_1uip(conflict_clause)
                print(f"[LEARN] Conflict at level {self.level}. Learned: {learned_clause}. Backjumping to {backjump_level}")
                self.formula.append(learned_clause)
                self.backjump(backjump_level)
            else:
                if len(self.assignment) == self.num_vars:
                    return True # SAT
                
                self.level += 1
                var, val = self.mcts_branching()
                print(f"[MCTS]  Level {self.level}: Guessing Var {var} = {val}")
                self.assign(var, val, self.level, None)
                
        return True


# ==========================================
# TEST CASE: The 1UIP Chain Reaction
# ==========================================
cnf_formula = [
    [-1, 2],       # A -> B
    [-1, 3],       # A -> C
    [-2, -3, 4],   # B & C -> D
    [-4, 5],       # D -> E
    [-4, 6],       # D -> F
    [-5, -6]       # Not E or Not F (Conflict!)
]

solver = SAT_1UIP_MCTS(cnf_formula, num_vars=6)

# A slightly smarter hack: Only force A=True if A is unassigned.
# Once 1UIP proves A=False, let the real MCTS take over.
original_mcts = solver.mcts_branching
def hacked_mcts(*args):
    if 1 not in solver.assignment:
        return (1, True)
    return original_mcts(*args)
    
solver.mcts_branching = hacked_mcts 


result = solver.solve()
print(f"\nSatisfiable: {result}")
if result:
    print(f"Final Assignment: {solver.assignment}")
