_variables_to_arrays() {
  local csv_variables="$1"
  local variables="${csv_variables//§§§/###}"
  variables="$(echo "$variables" | grep -E '#{3}([^###]*)#{3}' -o | sed 's/###//g')"
  local variable_array

  declare -A variable_array

  while IFS= read -r v; do
    variable_array["name"]="$(echo "$v" | awk -F'§' '{print $1}')"
    variable_array["value"]="$(echo "$v" | awk -F'§' '{print $2}')"
    variable_array["desc"]="$(echo "$v" | awk -F'§' '{print $3}')"

    echo "${variable_array[@]@K}"
  done <<< "$variables"
}
