
python ./scripts/sarikanto/save-dummyjson-products-to-json.py --directory ./waste

python ./scripts/sarikanto/transform-dummyjson-products-to-jsonld.py --products ./waste/dummyjson-products/products.json --directory ./prototype/web/core/public/assets/data

python ./scripts/sarikanto/extract-jsonld-products-thumbnail-picture.py --products ./prototype/web/core/public/assets/data/products --directory ./prototype/web/core/public/assets/images

python ./scripts/sarikanto/extract-jsonld-products-pictures.py --products ./prototype/web/core/public/assets/data/products --directory ./prototype/web/core/public/assets/images
