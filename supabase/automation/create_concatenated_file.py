import os

def concatenate_files(source_dir, file_list, output_file):
    """
    Concatenates the contents of specified files in a directory into a single output file.

    :param source_dir: The directory where the source files are located.
    :param file_list: A list of filenames to be concatenated.
    :param output_file: The path to the output file where the concatenated content will be written.
    """
    # Ensure the output directory exists
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    with open(output_file, 'w') as outfile:
        for file_name in file_list:
            try:
                with open(os.path.join(source_dir, file_name), 'r') as infile:
                    outfile.write(infile.read())
                    outfile.write('\n')  # Ensure separation between file contents
            except FileNotFoundError:
                print(f"File not found: {file_name}, skipping...")