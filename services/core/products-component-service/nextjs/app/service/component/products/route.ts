import { Product } from "../../product"

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
            <li class="picture-item content-tree-item item level-2">
                <img class="thumbnail-picture picture"
                    src="${thumbnail}"
                    alt="${product.name} product thumbnail picture">
                <dl class="main-content content">
                    <dt class="title label">${product.name}</dt>
                    <dd class="subtitle discount value">${product.discountPercentage}</dd>
                </dl>
            </li>
        `
    }).join("")

    const html = `<ol class="product-list content-tree-list list">${productList}</ol>`

    return new Response(html, {
        headers: {
            "Content-Type": "text/html"
        }
    })
}
