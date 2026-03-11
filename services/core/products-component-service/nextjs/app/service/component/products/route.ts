import { Product } from "@/app/types/product"

export async function GET(req: Request) {
    const { searchParams } = new URL(req.url)

    if (!searchParams.get("data")) {
        return new Response("Missing data parameter", { status: 400 })
    }

    const dataService = `${process.env.PRODUCT_DATA_SERVICE_ADDRESS}${searchParams.get("data")}`

    const dataProducts = await fetch(dataService).then(response => response.json())

    const products = dataProducts.products || []

    const productList = products.map((product: Product) => {
        const thumbnail = `${process.env.IMAGES_FILE_SERVICE_ADDRESS}${product.thumbnail}`

        return `
            <li class="picture-item content-tree-item item level-2"
                _="
                    on click
                        remove .hidden from #product-preview-tree

                        add .hidden to #product-search-tree
                        remove .hidden from #product-search-tree-idle

                        add .hidden to #product-sort-tree
                        add .hidden to #product-sort-tree-divider

                        add .hidden to #product-filter-tree
                        add .hidden to #product-filter-tree-divider

                    then tell <product-card/>
                        set @data-state to 'active'
                        set @data-component to '/service/component/products/${product.reference}/preview'
                        set @data-service to '/service/data/products/${product.reference}'
                    end
                ">
                <img class="thumbnail-picture picture"
                    src="${thumbnail}"
                    alt="${product.headline} product thumbnail picture">
                <dl class="main-content content">
                    <dt class="title label">
                        ${ product.headline }
                    </dt>
                    <dd class="subtitle discount value">
                        ${ Math.ceil(product.discountPercentage) }
                    </dd>
                </dl>
            </li>
            <li class="normal-spacing item spacer"></li>
        `
    }).join("")

    const html = `
        <ol class="product-list content-tree-list list">
            ${ productList }
        </ol>
    `

    return new Response(html, {
        headers: {
            "Content-Type": "text/html"
        }
    })
}
