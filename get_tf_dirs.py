import os

from sh import git
from git import Repo

"""
This script gets all terraform configuration directories that contain staged files, so they can be linted.
Configuration directories are recognized by .terraform-version files.
"""
TERRAFORM_IDENTIFIER = '.terraform-version'


def find_tf_dirs_in_root(tf_directories: list[str], root_dir: str, visited: set[str]):
    """
    Finds all subdirectories (relative to root) that contain Terraform configuration.
    :arg tf_directories: List of all directories containing Terraform configuration
    :arg root_dir: The root directory to evaluate; all its subdirectories will be evaluated
    :arg visited: Set of previously visited directories
    """
    for dir_path, dir_names, filenames in os.walk(root_dir):
        if dir_path in visited: continue
        visited.add(dir_path)
        for filename in filenames:
            if filename.endswith(TERRAFORM_IDENTIFIER):
                tf_directories.append(dir_path)
                break  # Move to the next directory

    return tf_directories


def find_all_tf_dirs(directories: set[str]):
    """
    Finds all directories that contain Terraform configuration.
    :arg directories: List of staged directories
    """
    tf_dirs = []
    visited = set()
    while directories:
        dir_path = directories.pop()
        if dir_path not in visited:
            find_tf_dirs_in_root(tf_dirs, dir_path, visited)
            visited.add(dir_path)
    return tf_dirs


repo = Repo(".")
assert not repo.bare, "Repo has not been initialized. Check configuration."

# Credit: https://stackoverflow.com/a/73583812
repo_root_dir = git("rev-parse", "--show-toplevel").rstrip()  # Get repo's root directory
all_files = git("ls-files", repo_root_dir, full_name=True).splitlines()  # List staged files relative to root directory
dirs = set([os.path.dirname(f) for f in all_files])  # Get directory names
dirs.discard("")  # Remove empty path - added by default when using git ls-files

# Print list as string, so it can be converted to Bash array
print("".join(find_all_tf_dirs(dirs)))
