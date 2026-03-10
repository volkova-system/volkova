#!/usr/bin/env python3
"""
Transform DummyJSON products to JSON-LD format.

This script converts DummyJSON product data to structured JSON-LD format
following the core product schema specification.
"""

import argparse
import json
import shutil
import sys
import re
from datetime import datetime
from pathlib import Path
from typing import cast

# Type alias for JSON data
JsonValue = str | int | float | bool | None | list['JsonValue'] | dict[str, 'JsonValue']
JsonDict = dict[str, JsonValue]


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


def read_products_file(products_path: str) -> JsonDict:
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
            data = cast(JsonDict, json.load(file))
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


def format_product_name(product: JsonDict) -> str:
    """
    Format product name from title.

    Args:
        product: DummyJSON product data

    Returns:
        Formatted product name string
    """

    name = str(product.get('title', '')).replace(' ', '-').lower()
    name = re.sub(r'[^a-z0-9\-]+', '_', name)
    name = re.sub(r'[\-]+', '-', name)
    name = re.sub(r'[_]+', '_', name)
    name = re.sub(r'(-_-)+', '-', name)

    return name


def generate_product_id(product: JsonDict) -> str:
    """
    Generate product ID from name and SKU.

    Args:
        product: DummyJSON product data

    Returns:
        String ID in format "name-sku"
    """

    name = format_product_name(product)
    sku = str(product.get('sku', product.get('id', ''))).lower()

    return f"{name}-{sku}"


def safe_float(value: JsonValue, default: float = 0.0) -> float:
    """
    Safely convert a JSON value to a float.

    Args:
        value: Input JSON value which may be int, float, str, or other types.
        default: Fallback value returned when conversion is not possible.

    Returns:
        float: Converted float value if coercible; otherwise the provided default.
    """

    if isinstance(value, (int, float)):
        return float(value)

    if isinstance(value, str):
        try:
            return float(value)

        except ValueError:
            return default

    return default


def calculate_net_price(price: float, discount_percentage: float) -> float:
    """
    Calculate net price from original price and discount percentage.

    Args:
        price: Original price value
        discount_percentage: Discount percentage (0-100)

    Returns:
        float: Net price after applying discount
    """

    if price <= 0:
        return 0.0

    if discount_percentage <= 0:
        return price

    if discount_percentage >= 100:
        return 0.0

    discount_amount = price * (discount_percentage / 100)
    net_price = price - discount_amount

    return max(0.0, net_price)

def map_product_to_jsonld(product: JsonDict) -> JsonDict:
    """
    Map DummyJSON product data to JSON-LD schema format.

    Args:
        product: DummyJSON product data

    Returns:
        Dict containing JSON-LD formatted product data
    """

    product_id = generate_product_id(product)
    current_time = datetime.now().isoformat() + "Z"

    # Calculate pricing
    price = safe_float(product.get('price', 0))
    discount_percentage = safe_float(product.get('discountPercentage', 0))
    net_price = calculate_net_price(price, discount_percentage)

    # Map basic product information
    jsonld_product = {
        "@context": "https://schema.org",
        "@type": "Product",
        "@id": product_id,

        "reference": product_id,
        "sku": str(product.get('sku', product.get('id', ''))).lower(),
        "name": format_product_name(product),
        "headline": str(product.get('title', '')),
        "description": str(product.get('description', '')),
        "url": f"/pages/products/{product_id}",
        "ratingValue": safe_float(product.get('rating', 0)),

        "priceCurrency": "php",
        "price": price,
        "netPrice": net_price,
        "discountPercentage": discount_percentage,

        "dateCreated": current_time,
        "dateModified": current_time,

        "thumbnail": f"/assets/images/products/thumbnails/{product_id}.webp",
        "images": [
            f"/assets/images/products/{product_id}/picture-{index}.webp"
            for index in range(len(images))
        ] if isinstance(images := product.get('images', []), list) else [],

        "keywords": [str(product.get('category', ''))],

        "cacheIdentifier": {
            "@type": "PropertyValue",

            "propertyID": "cache:key",
            "name": "cache_key",
            "description": "cache storage key",
            "value": f"product:{product_id}"
        },

        "aggregateRating": {
            "@type": "AggregateRating",

            "ratingValue": safe_float(product.get('rating', 0)),

            "bestRating": 5,
            "worstRating": 1
        },

        "offers": {
            "@type": "Offer",

            "priceCurrency": "php",
            "price": price,
            "netPrice": net_price,

            "availability": "https://schema.org/InStock",

            "priceSpecification": {
                "@type": "PriceSpecification",

                "priceCurrency": "php",
                "price": price
            },

            "discountPercentage": discount_percentage
        },

        "additionalProperty": cast(list[JsonDict], []),

        "raw": product
    }

    if 'brand' in product:
        jsonld_product["brand" ] = {
            "@type": "Brand",

            "name": str(product["brand"]).lower()
        }

    # Add additional properties if available
    additional_props = cast(list[JsonDict], jsonld_product["additionalProperty"])

    if 'weight' in product:
        additional_props.append({
            "@type": "PropertyValue",

            "name": "weight_unit",
            "description": "product weight unit",
            "value": "g"
        })

        additional_props.append({
            "@type": "PropertyValue",

            "name": "weight",
            "description": "product weight",
            "value": str(product['weight'])
        })

    # Add additional properties if available
    if 'dimensions' in product:
        dims = product.get('dimensions')
        if isinstance(dims, dict):
            width = safe_float(dims.get('width', 0))
            height = safe_float(dims.get('height', 0))
            depth = safe_float(dims.get('depth', 0))

            additional_props.append({
                "@type": "PropertyValue",

                "name": "dimension_unit",
                "description": "product dimension unit",
                "value": "cm"
            })

            additional_props.append({
                "@type": "PropertyValue",

                "name": "width",
                "description": "product width",
                "value": f"{width}"
            })

            additional_props.append({
                "@type": "PropertyValue",

                "name": "height",
                "description": "product height",
                "value": f"{height}"
            })

            additional_props.append({
                "@type": "PropertyValue",

                "name": "depth",
                "description": "product depth",
                "value": f"{depth}"
            })

    return cast(JsonDict, jsonld_product)


def save_jsonld_file(product_data: JsonDict,
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
            json.dump(product_data, file, indent=4, ensure_ascii=False)

    except Exception as e:
        print(f"Error: Failed to save JSON-LD file: {e}")
        sys.exit(1)


def process_products(products_data: JsonDict,
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
        if not isinstance(products, list):
            print("Error: Products data is not a list")
            sys.exit(1)

        if not products:
            print("Error: No products found in data")
            sys.exit(1)

        for product in products:
            if isinstance(product, dict):
                product_dict = cast(JsonDict, product)
                jsonld_product = map_product_to_jsonld(product_dict)

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
        products_data = read_products_file(cast(str, args.products))

        # Create output directory
        products_dir = create_products_directory(cast(str, args.directory))

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
