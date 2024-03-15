#!/bin/bash

#################################
#################################
# This scripts checks MD5 and creates symbolic
# links of given files while renaming the copy
# according to a tab delimited list.
# Specifically, this was created for sequencing
# data from the Cologne Center for Genomics.
# Symlinks are links that point to the original
# file and do not consume disk space. You can also
# set move_files=1 to actually move the files.
#################################
#################################


# Define your source and target directories
src_dir="/home/philipp/CCG/bastet2.ccg.uni-koeln.de/downloads/NGS_MYU10_hsmail_A006200382Kopie"
target_dir="/home/philipp/CCG/gz"

# Define the path to your tab-delimited text file
list_file="/home/philipp/CCG/bastet2.ccg.uni-koeln.de/downloads/NGS_MYU10_hsmail_A006200382Kopie/Sample_Names.tab"

# Set this to 1 if you want to check MD5 checksums, 0 otherwise
check_md5=1

# set this to 1 if you want to actualy move your original files instead of creating a symlink
move_files=0

# Path and filename of md5 checksums
hash_dir=$src_dir
hash_file="md5_checksums.tab"

### END OF CONFIG ###

# Check if the source directory exists
if [ ! -d "$src_dir" ]; then
    echo "Error: Source directory $src_dir does not exist."
    exit 1
fi

# Check if the target directory exists
if [ ! -d "$target_dir" ]; then
    echo "Error: Target directory $target_dir does not exist."
    exit 1
fi

# Check if the list file exists
if [ ! -f "$list_file" ]; then
    echo "Error: List file $list_file does not exist."
    exit 1
fi


# Check the MD5 checksum of the file, if check_md5 is set to 1
if [ "$check_md5" -eq 1 ]; then
	# Check if the hash file exists
	if [ ! -f "$hash_dir/$hash_file" ]; then
		echo "Error: Hashfile $hash_dir/$hash_file does not exist."
		exit 1
	fi
	echo "Checking hashes, found in $hash_dir/$hash_file."
	# Change the current directory to the source directory
    pushd "$hash_dir" > /dev/null
    if ! md5sum -c $hash_dir/$hash_file; then
        echo "Error: MD5 checksum failed."
        exit 1
	# Change the current directory back to the previous directory
    popd > /dev/null
    fi
fi


# Declare an associative array to hold the replacement list
declare -A replace_list

# Read the text file line by line, ignoring the header
while IFS=$'\t' read -r old new || [ -n "$old" ]; do
    # Check if the line is properly formatted with two fields
    if [ -z "$new" ]; then
        echo "Error: Line in $list_file is not properly formatted: $old"
        exit 1
    fi
    replace_list["$old"]="$new"
done < <(tail -n +2 "$list_file")

# Loop over all .gz files in the source directory
for file in "$src_dir"/*.gz
do
    # Check if the file exists
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        exit 1
    fi

    base=$(basename "$file")
    
    # Loop over the replacement list and replace strings in the filename
    for old in "${!replace_list[@]}"
    do
        base=${base//$old/${replace_list[$old]}}
    done
    
    # Check if the file already exists in the target directory
    if [ -e "$target_dir/$base" ]; then
		echo
        echo "Warning: File $target_dir/$base already exists. Skipping..."
        continue
    fi

	if [ "$move_files" -eq 0 ];	then
		# Create the symbolic link in the target directory
		ln -s "$file" "$target_dir/$base"
	elif [ "$move_files" -eq 1 ]; then
		mv "$file" "$target_dir/$base"
	fi
done