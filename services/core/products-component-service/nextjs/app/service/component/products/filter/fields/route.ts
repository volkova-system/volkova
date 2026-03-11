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
            <li class="input-tree-item item"
                _="">
                <data class="content"></data>
            </li>
            <li class="normal-spacing item spacer"></li>
        `
    }).join("")

    const html = `<ol class="product-list input-tree-list list">${productList}</ol>`

    return new Response(html, {
        headers: {
            "Content-Type": "text/html"
        }
    })
}
