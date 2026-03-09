
python ./scripts/sarikanto/save-dummyjson-products-to-json.py --directory ./waste

python ./scripts/sarikanto/transform-dummyjson-products-to-jsonld.py --products ./waste/dummyjson-products/products.json --directory ./assets/sarikanto/data

python ./scripts/sarikanto/extract-jsonld-products-thumbnail-picture.py --products ./assets/sarikanto/data --directory ./assets/sarikanto/images

python ./scripts/sarikanto/extract-jsonld-products-pictures.py --products ./assets/sarikanto/data --directory ./assets/sarikanto/images
