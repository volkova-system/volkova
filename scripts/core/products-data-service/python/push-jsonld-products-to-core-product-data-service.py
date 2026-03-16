#!/usr/bin/env python3
"""
Push JSON-LD products to core product data service.

This script processes JSON-LD files containing product data and pushes
each document to a specified service URI via POST requests.
"""

import argparse
import json
import sys
import urllib.request
import urllib.error
from pathlib import Path
from typing import cast
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

    path = Path(products_path).resolve()

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


def validate_service_uri(service_uri: str) -> str:
    """
    Validate the service URI parameter.

    Args:
        service_uri: Service URI for POST requests

    Returns:
        Validated service URI string

    Raises:
        SystemExit: If URI is invalid
    """

    if not service_uri or not service_uri.strip():
        print("Error: Service URI cannot be empty")
        sys.exit(1)

    uri = service_uri.strip()

    if not (uri.startswith('http://') or uri.startswith('https://')):
        print(f"Error: Service URI must start with http:// or https://")
        sys.exit(1)

    return uri


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


def read_jsonld_document(jsonld_file: Path) -> dict[str, object]:
    """
    Read and parse JSON-LD document from file.

    Args:
        jsonld_file: Path to JSON-LD file

    Returns:
        Parsed JSON-LD document as dictionary

    Raises:
        SystemExit: If file cannot be read or parsed
    """

    try:
        with open(jsonld_file, 'r', encoding='utf-8') as f:
            data = cast(dict[str, object], json.load(f))
            return data

    except (OSError, json.JSONDecodeError) as e:
        print(f"Error: Cannot read JSON-LD file {jsonld_file}: {e}")
        sys.exit(1)


def push_jsonld_document(document: dict[str, object],
                        service_uri: str) -> None:
    """
    Push JSON-LD document to service via POST request.

    Args:
        document: JSON-LD document to push
        service_uri: Service URI for POST request

    Raises:
        SystemExit: If POST request fails
    """

    try:
        json_data = json.dumps(document, ensure_ascii=False).encode('utf-8')

        request = urllib.request.Request(
            service_uri,
            data=json_data,
            headers={
                'Content-Type': 'application/ld+json',
                'Content-Length': str(len(json_data)),
                'User-Agent': 'Python/3 JSON-LD Push Script'
            },
            method='POST'
        )

        response: HTTPResponse
        with cast(HTTPResponse, urllib.request.urlopen(request)) as response:
            if response.status not in (200, 201, 202):
                print(f"Error: Service returned status {response.status}")
                sys.exit(1)

    except urllib.error.URLError as e:
        print(f"Error: Failed to push document to service: {e}")
        sys.exit(1)

    except Exception as e:
        print(f"Error: Unexpected error during POST request: {e}")
        sys.exit(1)


def main() -> None:
    """
    Main function to orchestrate JSON-LD document pushing process.
    """

    parser = argparse.ArgumentParser(
        description="Push JSON-LD products to core product data service"
    )

    _ = parser.add_argument(
        "--products",
        required=True,
        help="Directory path containing JSON-LD files"
    )

    _ = parser.add_argument(
        "--service",
        required=True,
        help="Service URI for POST requests"
    )

    args = parser.parse_args()

    # Validate inputs
    products_dir = validate_products_directory(cast(str, args.products))
    service_uri = validate_service_uri(cast(str, args.service))

    # Get JSON-LD files
    jsonld_files = get_jsonld_files(products_dir)
    print(f"Found {len(jsonld_files)} JSON-LD files")

    # Process each JSON-LD file
    for jsonld_file in jsonld_files:
        print(f"Processing: {jsonld_file}")

        # Read JSON-LD document
        document = read_jsonld_document(jsonld_file)

        # Push document to service
        push_jsonld_document(document, service_uri)
        print(f"Successfully pushed: {jsonld_file.name}")

    print(f"Successfully processed {len(jsonld_files)} JSON-LD documents")


if __name__ == "__main__":
    main()
