import { Product } from "@/app/types/product"

export async function GET(req: Request) {
    const { searchParams } = new URL(req.url)

    if (!searchParams.get("data")) {
        return new Response("Missing data parameter", { status: 400 })
    }

    const dataService = `${process.env.PRODUCT_DATA_SERVICE_ADDRESS}${searchParams.get("data")}`

    const dataProduct = await fetch(dataService).then(response => response.json())

    const product: Product = dataProduct.product || {}

    const productPicture = `${process.env.IMAGES_FILE_SERVICE_ADDRESS}${product.images[0]}`

    const html = `
        <ol class="product-list content-tree-list list">
            <li class="card-item-picture focus-tree-item item level-7">
                <img class="picture"
                    src="${productPicture}"
                    alt="${product.headline} product picture">
            </li>
            <li class="normal-spacing item spacer"></li>
            <li class="card-item-title focus-tree-item item level-2">
                <div class="spacer"></div>
                <data class="title value main-content content"
                    value="${product.headline}">
                    ${product.headline}
                </data>
                <div class="spacer"></div>
            </li>
            <li class="normal-spacing item spacer"></li>
            <li class="card-item-description focus-tree-item item">
                <div class="spacer"></div>
                <data class="description value support-content content">
                    ${product.description}
                </data>
                <div class="spacer"></div>
            </li>
            <li class="normal-spacing item spacer"></li>
            <li class="card-item-details focus-tree-item item">
                <div class="spacer"></div>
                <div class="content">
                    <data class="deprecated currency-${product.priceCurrency} currency value"
                        value="${product.price}">${product.price}</data>
                    <data class="currency-${product.priceCurrency} currency value"
                        value="${product.netPrice}">${product.netPrice.toFixed(2)}</data>
                </div>
                <div class="spacer"></div>
            </li>
        </ol>
    `

    return new Response(html, {
        headers: {
            "Content-Type": "text/html"
        }
    })
}
