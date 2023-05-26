restart

# Initial values
add_force CLK {0 0ns} {1 5ns} -repeat_every 10ns
add_force RESET 0
add_force W_CMD 1
run 100ns

# Release RESET# (active low)
add_force RESET 1
run 100ns

# Run read cycle (active low)
add_force R_CMD 0
run 150ns

# Run write cycle (active low)
add_force R_CMD 1
add_force W_CMD 0
run 150ns
