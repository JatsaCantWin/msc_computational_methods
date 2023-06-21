#!/bin/bash

# Ensure that the script is run with the correct number of arguments
if [[ $# -ne 4 ]]; then
  echo "Invalid number of arguments. Please provide 4 arguments."
  exit 1
fi

# Extract the arguments from the command line
i=$1
p=$2
assignment_number=$3
f=$4

# Ensure that i is a positive integer
if [[ ! $i =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid input for i. Please enter a positive integer."
  exit 1
fi

# Ensure that p is a positive integer
if [[ ! $p =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid input for p. Please enter a positive integer."
  exit 1
fi

# Ensure that assignment_number is either 1 or 2
if [[ ! $assignment_number =~ ^[1-2]$ ]]; then
  echo "Invalid input for assignment_number. Please enter either 1 or 2."
  exit 1
fi

# Ensure that f is either 1, 2, or 3
if [[ ! $f =~ ^[1-3]$ ]]; then
  echo "Invalid input for f. Please enter either 1, 2, or 3."
  exit 1
fi

# Define the initial input text
initial_input="deck
mesh
enrich,global,order=$p
plot
plot
end"

repeated_input="
solve
"

# Modify the profile line based on the value of f
if [[ $f == 3 ]]; then
  repeated_input+="
twodim"
else
  repeated_input+="
profile=1"
fi

# Define the repeated input text
repeated_input+="
errest"

# Add mesh line for assignment_number = 1
if [[ $assignment_number == 1 ]]; then
  repeated_input+="
mesh"
fi

# Add adapth line for assignment_number = 2
if [[ $assignment_number == 2 ]]; then
  repeated_input+="
adapth"
fi

repeated_input+="
refine,global
end
"

# Append the repeated_input string i times to the initial_input string
for ((count=1; count<i; count++)); do
  initial_input="$initial_input
$repeated_input"
done

# Print the final result
echo "$initial_input" | ../a.out_debian | tee output.txt
sed -i '/\*\*\*ERROR READING INPUT FILE/,$ d' output.txt
