#!/usr/bin/env python3
"""
Extract product images from JSON-LD files.

This script processes JSON-LD files containing product data, extracts
image URLs and product IDs, then downloads the images with index-based
filenames to product-specific directories in the output location.
"""

import argparse
import json
import shutil
import sys
import urllib.request
import urllib.error
from pathlib import Path
from typing import cast
from urllib.parse import urlparse
from http.client import HTTPResponse


def validate_products_directory(products_path: str) -> Path:
    """
    Validate that the products directory exists and contains JSON-LD files.

    Args:
        products_path: Path to directory containing JSON-LD files

    Returns:
        Path object of validated directory

    Raises:
        SystemExit: If directory invalid or no JSON-LD files found
    """

    path = Path(products_path)

    if not path.exists():
        print(f"Error: Products directory does not exist: {products_path}")
        sys.exit(1)

    if not path.is_dir():
        print(f"Error: Products path is not a directory: {products_path}")
        sys.exit(1)

    jsonld_files = list(path.glob("*.jsonld"))
    if not jsonld_files:
        print(f"Error: No JSON-LD files found in: {products_path}")
        sys.exit(1)

    return path


def validate_output_directory(output_path: str) -> Path:
    """
    Validate and prepare the output directory.

    Args:
        output_path: Path to output directory

    Returns:
        Path object of validated directory

    Raises:
        SystemExit: If directory cannot be created or accessed
    """

    path = Path(output_path)

    try:
        path.mkdir(parents=True, exist_ok=True)

    except OSError as e:
        print(f"Error: Cannot create output directory {output_path}: {e}")
        sys.exit(1)

    if not path.is_dir():
        print(f"Error: Output path is not a directory: {output_path}")
        sys.exit(1)

    return path


def get_jsonld_files(products_dir: Path) -> list[Path]:
    """
    Get all JSON-LD file paths in absolute form.

    Args:
        products_dir: Directory containing JSON-LD files

    Returns:
        List of absolute paths to JSON-LD files
    """

    jsonld_files = list(products_dir.glob("*.jsonld"))
    return [file.resolve() for file in jsonld_files]


def extract_product_data(jsonld_file: Path) -> tuple[str, list[str]]:
    """
    Extract product ID and images array from JSON-LD file.

    Args:
        jsonld_file: Path to JSON-LD file

    Returns:
        Tuple of (product_id, images_list)

    Raises:
        SystemExit: If file cannot be read or required fields missing
    """

    try:
        with open(jsonld_file, 'r', encoding='utf-8') as f:
            data = cast(dict[str, object], json.load(f))

    except (OSError, json.JSONDecodeError) as e:
        print(f"Error: Cannot read JSON-LD file {jsonld_file}: {e}")
        sys.exit(1)

    product_id = data.get('@id')
    raw = cast(dict[str, object], data.get('raw', {}))
    images = raw.get('images')

    if not product_id:
        print(f"Error: Missing '@id' field in {jsonld_file}")
        sys.exit(1)

    if not images:
        print(f"Error: Missing 'images' field in {jsonld_file}")
        sys.exit(1)

    if not isinstance(images, list):
        print(f"Error: 'images' field is not an array in {jsonld_file}")
        sys.exit(1)

    return str(product_id), [str(img) for img in cast(list[str], images)]


def create_product_directory(output_dir: Path, product_id: str) -> Path:
    """
    Create or recreate the products/<product_id> directory.

    Args:
        output_dir: Base output directory
        product_id: Product ID for directory name

    Returns:
        Path to product directory

    Raises:
        SystemExit: If directory operations fail
    """

    product_dir = output_dir / "products" / product_id

    try:
        if product_dir.exists():
            shutil.rmtree(product_dir)

        product_dir.mkdir(parents=True)

    except OSError as e:
        print(f"Error: Cannot create product directory: {e}")
        sys.exit(1)

    return product_dir


def download_image(image_url: str, index: int, product_dir: Path) -> None:
    """
    Download image and save with picture-<index> filename.

    Args:
        image_url: URL of image
        index: Index for filename
        product_dir: Directory to save image

    Raises:
        SystemExit: If download or save operations fail
    """

    try:
        # Get file extension from URL
        parsed_url = urlparse(image_url)
        path_parts = parsed_url.path.split('.')
        extension = f".{path_parts[-1]}" if len(path_parts) > 1 else ""

        # Create filename with index
        filename = f"picture-{index}{extension}"
        filepath = product_dir / filename

        # Delete existing file if present
        if filepath.exists():
            filepath.unlink()

        req = urllib.request.Request(
            image_url,
            headers={
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " +
                             "AppleWebKit/537.36 (KHTML, like Gecko) " +
                             "Chrome/122.0.0.0 Safari/537.36",
                "Accept": "image/avif,image/webp,image/apng,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
                "Referer": "https://dummyjson.com/",
                "Accept-Encoding": "gzip, deflate"
            }
        )

        response: HTTPResponse
        with cast(HTTPResponse, urllib.request.urlopen(req, timeout=30)) as response:
            data = response.read()
        with open(filepath, "wb") as f:
            _ = f.write(data)

    except (OSError, urllib.error.URLError) as e:
        print(f"Error: Cannot download image {image_url}: {e}")
        sys.exit(1)


def main() -> None:
    """
    Main function to orchestrate image extraction process.
    """

    parser = argparse.ArgumentParser(
        description="Extract product images from JSON-LD files"
    )

    _ = parser.add_argument(
        "--products",
        required=True,
        help="Directory path containing JSON-LD files"
    )

    _ = parser.add_argument(
        "--directory",
        required=True,
        help="Output directory path for saving images"
    )

    args = parser.parse_args()

    # Validate inputs
    products_dir = validate_products_directory(cast(str, args.products))
    output_dir = validate_output_directory(cast(str, args.directory))

    # Get JSON-LD files
    jsonld_files = get_jsonld_files(products_dir)
    print(f"Found {len(jsonld_files)} JSON-LD files")

    # Process each JSON-LD file
    for jsonld_file in jsonld_files:
        print(f"Processing: {jsonld_file}")

        # Extract product data
        product_id, images = extract_product_data(jsonld_file)

        # Create product directory
        product_dir = create_product_directory(output_dir, product_id)
        print(f"Created product directory: {product_dir}")

        # Download each image
        for index, image_url in enumerate(images):
            download_image(image_url, index, product_dir)
            print(f"Downloaded image {index} for product: {product_id}")

    print(f"Successfully processed {len(jsonld_files)} products")


if __name__ == "__main__":
    main()
