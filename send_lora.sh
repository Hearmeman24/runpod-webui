#!/bin/bash

# Function to check if runpodctl is installed
check_runpodctl_installed() {
    if ! command -v runpodctl &> /dev/null
    then
        echo "runpodctl could not be found, please install it first."
        exit 1
    fi
}

# Scan for .safetensors files in the current directory
safetensors_files=(*.safetensors)

# Check if there are any .safetensors files in the current directory
if [ ${#safetensors_files[@]} -eq 0 ]; then
    echo "No .safetensors files found in the current directory."
    exit 1
fi

# Display found .safetensors files with numbers
echo "Found the following .safetensors files:"
for i in "${!safetensors_files[@]}"; do
    echo "[$i] ${safetensors_files[$i]}"
done

# Prompt the user to select a file
echo -n "Enter the number of the file you want to process: "
read file_index

# Validate input
if ! [[ "$file_index" =~ ^[0-9]+$ ]] || [ "$file_index" -ge ${#safetensors_files[@]} ]; then
    echo "Invalid selection. Please enter a number between 0 and $((${#safetensors_files[@]}-1))."
    exit 1
fi

# Get the selected file
file_to_rename="${safetensors_files[$file_index]}"
echo "You selected: $file_to_rename"

# Prompt the user for the epoch number
echo -n "Enter the epoch number: "
read epoch_number

# Rename the selected file to epoch_<user_inputted_number>.safetensors
new_name="epoch_${epoch_number}.safetensors"
mv "$file_to_rename" "$new_name"

# Run the command with the renamed file
echo "Renaming complete. Running the command..."
runpodctl send "$(realpath "$new_name")"

# Print the output
echo "Process complete for $new_name."