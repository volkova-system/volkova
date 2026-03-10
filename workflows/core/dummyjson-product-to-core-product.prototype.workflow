
python ./scripts/core/save-dummyjson-products-to-json.py --directory ./waste

python ./scripts/core/transform-dummyjson-products-to-jsonld.py --products ./waste/dummyjson-products/products.json --directory ./prototype/web/core/public/assets/data

python ./scripts/core/extract-jsonld-products-thumbnail-picture.py --products ./prototype/web/core/public/assets/data/products --directory ./prototype/web/core/public/assets/images

python ./scripts/core/extract-jsonld-products-pictures.py --products ./prototype/web/core/public/assets/data/products --directory ./prototype/web/core/public/assets/images

python ./scripts/core/push-jsonld-products-to-core-product-data-service.py --products ./prototype/web/core/public/assets/data/products --service http://localhost:4979/service/products/push
