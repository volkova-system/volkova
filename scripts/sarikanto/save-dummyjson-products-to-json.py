#!/usr/bin/env python3
"""
Standalone CLI script to fetch DummyJSON products and save to JSON file.

This script fetches product data from https://dummyjson.com/products API
and saves it to a JSON file in a specified directory structure.

Usage:
    python save-dummyjson-products-to-json.py <directory_path> [skip] [limit]

Arguments:
    directory_path: Target directory where dummyjson-products will be created
    skip: Number of products to skip (optional, default: 0)
    limit: Maximum number of products to fetch (optional, default: 30)

Example:
    python save-dummyjson-products-to-json.py ./data 10 20
"""

import sys
import os
import json
import urllib.request
import urllib.parse
from pathlib import Path


def validate_arguments():
    """
    Validate command line arguments.

    Returns:
        tuple: (directory_path, skip, limit)

    Raises:
        SystemExit: If arguments are invalid
    """
    if len(sys.argv) < 2:
        print("Error: Directory path is required")
        print("Usage: python script.py <directory_path> [skip] [limit]")
        sys.exit(1)

    directory_path = sys.argv[1]
    skip = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    limit = int(sys.argv[3]) if len(sys.argv) > 3 else 30

    if skip < 0:
        print("Error: Skip parameter must be non-negative")
        sys.exit(1)

    if limit <= 0:
        print("Error: Limit parameter must be positive")
        sys.exit(1)

    return directory_path, skip, limit


def fetch_products(skip=0, limit=30):
    """
    Fetch products from DummyJSON API.

    Args:
        skip (int): Number of products to skip
        limit (int): Maximum number of products to fetch

    Returns:
        dict: JSON response from API

    Raises:
        SystemExit: If API request fails
    """
    base_url = "https://dummyjson.com/products"
    params = urllib.parse.urlencode({"skip": skip, "limit": limit})
    url = f"{base_url}?{params}"

    try:
        request = urllib.request.Request(url)
        request.add_header('User-Agent', 'Python/3 CLI Script')

        with urllib.request.urlopen(request) as response:
            if response.status != 200:
                print(f"Error: API returned status {response.status}")
                sys.exit(1)

            data = json.loads(response.read().decode('utf-8'))
            return data

    except urllib.error.URLError as e:
        print(f"Error: Failed to fetch data from API - {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON response - {e}")
        sys.exit(1)


def create_output_directory(base_path):
    """
    Create dummyjson-products directory in the specified path.

    Args:
        base_path (str): Base directory path

    Returns:
        Path: Path to the created directory

    Raises:
        SystemExit: If directory creation fails
    """
    try:
        base_dir = Path(base_path)
        if not base_dir.exists():
            print(f"Error: Base directory '{base_path}' does not exist")
            sys.exit(1)

        output_dir = base_dir / "dummyjson-products"
        output_dir.mkdir(exist_ok=True)
        return output_dir

    except PermissionError:
        print(f"Error: Permission denied creating directory in '{base_path}'")
        sys.exit(1)
    except OSError as e:
        print(f"Error: Failed to create directory - {e}")
        sys.exit(1)


def save_products_json(products_data, output_directory):
    """
    Save products data to JSON file.

    Args:
        products_data (dict): Products data from API
        output_directory (Path): Directory to save the file

    Raises:
        SystemExit: If file save fails
    """
    try:
        output_file = output_directory / "products.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(products_data, f, indent=2, ensure_ascii=False)

        print(f"Successfully saved {len(products_data.get('products', []))} "
              f"products to {output_file}")

    except PermissionError:
        print(f"Error: Permission denied writing to '{output_directory}'")
        sys.exit(1)
    except OSError as e:
        print(f"Error: Failed to save file - {e}")
        sys.exit(1)


def main():
    """
    Main function to orchestrate the product fetching and saving process.
    """
    # Validate command line arguments
    directory_path, skip, limit = validate_arguments()

    # Fetch products from API
    products_data = fetch_products(skip, limit)

    # Create output directory
    output_dir = create_output_directory(directory_path)

    # Save products to JSON file
    save_products_json(products_data, output_dir)


if __name__ == "__main__":
    main()
