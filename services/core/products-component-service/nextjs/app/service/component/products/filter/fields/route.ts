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
                const label = field.replace(/([a-z0-9])([A-Z])/g, "$1 $2")
                const encodedValue = encodeURIComponent(value)

                return `
                    <li class="product-filter-field input-tree-item item"
                        data-field="${ field }"
                        data-value="${ value }">
                        <dl class="content">
                            <dt class="label">${ label }</dt>
                            <dd class="value">
                                ${ value.split(/\-/).join(" ") }
                            </dd>
                        </dl>
                        <div class="spacer"></div>
                        <button class="icon-control control"
                            aria-label="filter ${ label } by ${ value }"
                            _="
                                on click
                                    add .hidden to me
                                    add .hidden to #product-preview-tree
                                    remove .hidden from #product-filter-tree-divider

                                    set field to '${ field }'
                                    set value to '${ encodedValue }'
                                    set @data-state of <product-list/> to 'filter'
                                    set @data-service of <product-list/> to '/service/data/products/filter?field=' + field + '&value=' + value
                            ">
                            <svg class="icon">
                                <use href="/assets/images/feather-sprite.svg#filter" />
                            </svg>
                        </button>
                        <button class="icon-control control"
                            aria-label="clear filter ${ label } by ${ value }"
                            _="
                                on click
                                    add .hidden to me
                                    add .hidden to #product-preview-tree

                                    set field to '${ field }'
                                    set value to '${ encodedValue }'
                                    set @data-state of <product-list/> to 'filter'
                                    set @data-service of <product-list/> to '/service/data/products/filter?field=' + field + '&value=' + value
                            ">
                            <svg class="icon">
                                <use href="/assets/images/feather-sprite.svg#filter" />
                            </svg>
                        </button>
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
