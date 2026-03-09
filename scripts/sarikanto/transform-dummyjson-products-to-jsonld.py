#!/usr/bin/env python3
"""
Transform DummyJSON products to JSON-LD format.

This script converts DummyJSON product data to structured JSON-LD format
following the sarikanto product schema specification.
"""

import argparse
import json
import shutil
import sys
from datetime import datetime
from pathlib import Path
from typing import cast

# Type alias for JSON data
JsonValue = str | int | float | bool | None | list['JsonValue'] | dict[str, 'JsonValue']


def parse_arguments() -> argparse.Namespace:
    """
    Parse command line arguments.

    Returns:
        argparse.Namespace: Parsed command line arguments
    """

    parser = argparse.ArgumentParser(
        description="Transform DummyJSON products to JSON-LD format"
    )

    _ = parser.add_argument(
        "--products",
        required=True,
        help="Path to products.json file containing DummyJSON products"
    )

    _ = parser.add_argument(
        "--directory",
        required=True,
        help="Output directory path where JSON-LD files will be saved"
    )

    return parser.parse_args()


def read_products_file(products_path: str) -> dict[str, JsonValue]:
    """
    Read and parse the products JSON file.

    Args:
        products_path: Path to the products.json file

    Returns:
        Dict containing the parsed JSON data

    Raises:
        SystemExit: If file cannot be read or parsed
    """

    try:
        with open(products_path, 'r', encoding='utf-8') as file:
            data = cast(dict[str, JsonValue], json.load(file))
            return data

    except FileNotFoundError:
        print(f"Error: Products file not found: {products_path}")
        sys.exit(1)

    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in products file: {e}")
        sys.exit(1)

    except Exception as e:
        print(f"Error: Failed to read products file: {e}")
        sys.exit(1)


def create_products_directory(output_dir: str) -> Path:
    """
    Create products directory, removing existing one if present.

    Args:
        output_dir: Base output directory path

    Returns:
        Path object for the products directory

    Raises:
        SystemExit: If directory operations fail
    """
    try:
        products_dir = Path(output_dir) / "products"
        if products_dir.exists():
            shutil.rmtree(products_dir)
        products_dir.mkdir(parents=True, exist_ok=True)
        return products_dir
    except Exception as e:
        print(f"Error: Failed to create products directory: {e}")
        sys.exit(1)


def generate_product_id(product: dict[str, JsonValue]) -> str:
    """
    Generate product ID from name and SKU.

    Args:
        product: DummyJSON product data

    Returns:
        String ID in format "name-sku"
    """
    name = str(product.get('title', '')).lower().replace(' ', '-')
    sku = str(product.get('sku', product.get('id', '')))
    return f"{name}-{sku}"


def map_product_to_jsonld(product: dict[str, JsonValue]) -> dict[str, JsonValue]:
    """
    Map DummyJSON product data to JSON-LD schema format.

    Args:
        product: DummyJSON product data

    Returns:
        Dict containing JSON-LD formatted product data
    """
    product_id = generate_product_id(product)
    current_time = datetime.now().isoformat() + "Z"

    # Map basic product information
    jsonld_product = {
        "@context": "https://schema.org",
        "@type": "Product",
        "@id": product_id,
        "sku": str(product.get('sku', product.get('id', ''))),
        "name": str(product.get('title', '')),
        "headline": str(product.get('title', '')),
        "description": str(product.get('description', '')),
        "url": f"https://example.com/products/{product_id}",
        "ratingValue": float(product.get('rating', 0)),
        "priceCurrency": "usd",
        "price": float(product.get('price', 0)),
        "discountPercentage": float(product.get('discountPercentage', 0)),
        "dateCreated": current_time,
        "dateModified": current_time,
        "thumbnail": str(product.get('thumbnail', '')),
        "image": product.get('images', []),
        "keywords": [str(product.get('category', ''))],
        "cacheIdentifier": {
            "@type": "PropertyValue",
            "propertyID": "cache:key",
            "name": "cache_key",
            "value": f"product:{product.get('id', '')}"
        },
        "brand": {
            "@type": "Brand",
            "name": str(product.get('brand', ''))
        },
        "aggregateRating": {
            "@type": "AggregateRating",
            "ratingValue": float(product.get('rating', 0)),
            "bestRating": 5,
            "worstRating": 1
        },
        "offers": {
            "@type": "Offer",
            "priceCurrency": "usd",
            "price": float(product.get('price', 0)),
            "availability": "https://schema.org/InStock",
            "priceSpecification": {
                "@type": "PriceSpecification",
                "priceCurrency": "usd",
                "price": float(product.get('price', 0))
            },
            "discountPercentage": float(product.get('discountPercentage', 0))
        },
        "additionalProperty": []
    }

    # Add additional properties if available
    if 'weight' in product:
        jsonld_product["additionalProperty"].append({
            "@type": "PropertyValue",
            "name": "weight",
            "description": "Product Weight",
            "value": str(product['weight'])
        })

    if 'dimensions' in product:
        dims = product['dimensions']
        width = dims.get('width', 0)
        height = dims.get('height', 0)
        depth = dims.get('depth', 0)
        jsonld_product["additionalProperty"].append({
            "@type": "PropertyValue",
            "name": "dimensions",
            "description": "Product Dimensions",
            "value": f"{width}x{height}x{depth}"
        })

    return jsonld_product


def save_jsonld_file(product_data: dict[str, JsonValue],
                     products_dir: Path) -> None:
    """
    Save JSON-LD product data to file.

    Args:
        product_data: JSON-LD formatted product data
        products_dir: Directory to save the file in

    Raises:
        SystemExit: If file cannot be saved
    """
    try:
        filename = f"{product_data['@id']}.jsonld"
        filepath = products_dir / filename

        # Remove existing file if present
        if filepath.exists():
            filepath.unlink()

        with open(filepath, 'w', encoding='utf-8') as file:
            json.dump(product_data, file, indent=2, ensure_ascii=False)

    except Exception as e:
        print(f"Error: Failed to save JSON-LD file: {e}")
        sys.exit(1)


def process_products(products_data: dict[str, JsonValue],
                     products_dir: Path) -> None:
    """
    Process all products and convert to JSON-LD format.

    Args:
        products_data: DummyJSON products data
        products_dir: Directory to save JSON-LD files

    Raises:
        SystemExit: If processing fails
    """
    try:
        products = products_data.get('products', [])
        if not products:
            print("Error: No products found in data")
            sys.exit(1)

        for product in products:
            jsonld_product = map_product_to_jsonld(product)
            save_jsonld_file(jsonld_product, products_dir)

        print(f"Successfully processed {len(products)} products")

    except Exception as e:
        print(f"Error: Failed to process products: {e}")
        sys.exit(1)


def main() -> None:
    """
    Main function to orchestrate the transformation process.
    """
    try:
        # Parse command line arguments
        args = parse_arguments()

        # Read products data
        products_data = read_products_file(args.products)

        # Create output directory
        products_dir = create_products_directory(args.directory)

        # Process and save products
        process_products(products_data, products_dir)

    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
