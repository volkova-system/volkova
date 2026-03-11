import { Product } from "@/app/types/product"

export async function GET(req: Request) {
    const { searchParams } = new URL(req.url)

    if (!searchParams.get("data")) {
        return new Response("Missing data parameter", { status: 400 })
    }

    const dataService = `${process.env.PRODUCT_DATA_SERVICE_ADDRESS}${searchParams.get("data")}`

    const dataFilterFields = await fetch(dataService).then(response => response.json())

    const filterFields: Record<string, string[]> = dataFilterFields.filterFields || {}

    const filters = Object.entries( filterFields )
        .map(([field, values]) => {
            return values.map((value)=> {
                return `
                    <li class="product-filter-field input-tree-item item"
                        _="">
                        <div class="spacer"></div>
                        <div class="content">${ value.split(/\-/).join(" ") }</div>
                        <div class="spacer"></div>
                    </li>
                    <li class="normal-spacing item spacer"></li>
                `
            }).join("")
        }).join("")

    const html = `
        <ol id="product-filter-fields"
            class="product-filter-fields input-tree-list list">
            ${ filters }
        </ol>
    `

    return new Response(html, {
        headers: {
            "Content-Type": "text/html"
        }
    })
}
