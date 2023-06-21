#!/bin/bash

# Check if files are provided as arguments
if [[ $# -eq 0 ]]; then
  echo "Please provide files as arguments."
  exit 1
fi

# Create a temporary directory
temp_dir=$(mktemp -d)

# Prepare the gnuplot script
gnuplot_script=$(cat <<EOF
set datafile separator " "
set title "Zaleznosc wielkosci bledu od ilosci stopnii swobody"
set xlabel "Liczba Stopni Swobody (log10)"
set ylabel "Blad (log10)"
plot
EOF
)

# Iterate over the provided files
i=1
for filename in "$@"; do
  # Check if the file exists
  if [[ ! -f "$filename" ]]; then
    echo "File '$filename' does not exist."
    exit 1
  fi

  # Grep lines containing NDOF or H1 and extract content after log10=
  data=$(grep -E "NDOF|H1:" "$filename" | awk -F"log10=" '{print $2}')

  # Create a temporary file to store the formatted data
  formatted_data_file="$temp_dir/formatted_data_$i.txt"

  # Format the data as pairs of x and y values
  echo "$data" | awk 'NR%2==1 {x=$0} NR%2==0 {print x, $0}' > "$formatted_data_file"

  # Append the line to the gnuplot script
  line_title=$(basename "$filename")
  gnuplot_script+="\"$formatted_data_file\" title \"$line_title\" with linespoints, "

  ((i++))
done

# Remove the trailing comma and space from the gnuplot script
gnuplot_script="${gnuplot_script%,*}"

# Create a temporary gnuplot script file
gnuplot_script_file="$temp_dir/script.gp"
echo "$gnuplot_script" > "$gnuplot_script_file"

# Execute gnuplot with the script file
gnuplot -persist "$gnuplot_script_file"

# Clean up the temporary directory
rm -r "$temp_dir"

