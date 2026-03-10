export async function GET(req: Request) {
    const { searchParams } = new URL(req.url)

    const dataService = searchParams.get("data")

    if (!dataService) {
        return new Response("Missing src parameter", { status: 400 })
    }

    const dataProducts = await fetch(dataService).then(response => response.json())

    const products = dataProducts.products || []

    const items = products.map((p: any) => `
        <li class="picture-item content-tree-item item level-2">
            <img class="thumbnail-picture picture"
                src="/assets/images/products/essence-mascara-lash-princess.webp"
                alt="Essence Mascara Lash Princess product thumbnail picture">
            <dl class="main-content content">
                <dt class="title label">Essence Mascara Lash Princess</dt>
                <dd class="subtitle discount value">5</dd>
            </dl>
        </li>
    `).join("")

    const html = `<ol class="product-list content-tree-list list">${items}</ol>`

    return new Response(html, {
        headers: {
            "Content-Type": "text/html"
        }
    })
}
