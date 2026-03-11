import { Product } from "@/app/types/product"

export async function GET(req: Request) {
    const { searchParams } = new URL(req.url)

    if (!searchParams.get("data")) {
        return new Response("Missing data parameter", { status: 400 })
    }

    const dataService = `${process.env.PRODUCT_DATA_SERVICE_ADDRESS}${searchParams.get("data")}`

    const dataSortCriteria = await fetch(dataService)
        .then(response => response.json())

    const sortCriteria = dataSortCriteria.sortCriteria || []

    const criteria = sortCriteria.map((criterion: string) => {
        const label = criterion.replace(/([a-z0-9])([A-Z])/g, "$1 $2");

        return `
            <li class="product-sort-criterion input-tree-item item"
                data-criterion="${ criterion }">
                <div class="content">
                    <data class="value">${ label }</data>
                </div>
                <button class="icon-control control"
                    aria-label="sort ${ label } descending"
                    _="
                        on click
                            set criterion to '-${ criterion }'
                            set @data-state of <product-list/> to 'sort'
                            set @data-service of <product-list/> to '/service/data/products/sort?criterion=' + criterion
                    ">
                    <svg class="icon">
                        <use href="/assets/images/feather-sprite.svg#chevrons-down" />
                    </svg>
                </button>
                <button class="icon-control control"
                    aria-label="sort ${ label } ascending"
                    _="
                        on click
                            set criterion to '${ criterion }'
                            set @data-state of <product-list/> to 'sort'
                            set @data-service of <product-list/> to '/service/data/products/sort?criterion=' + criterion
                    ">
                    <svg class="icon">
                        <use href="/assets/images/feather-sprite.svg#chevrons-up" />
                    </svg>
                </button>
            </li>
            <li class="normal-spacing item spacer"></li>
        `
    }).join("")

    const html = `
        <ol id="product-sort-criteria"
            class="product-sort-criteria input-tree-list list">
            ${criteria}
        </ol>
    `

    return new Response(html, {
        headers: {
            "Content-Type": "text/html"
        }
    })
}
