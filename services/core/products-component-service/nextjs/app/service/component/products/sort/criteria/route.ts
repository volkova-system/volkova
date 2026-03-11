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

    const criteria = sortCriteria.map((criterion: string, index: number) => {
        const label = criterion.replace(/([a-z0-9])([A-Z])/g, "$1 $2");

        return `
            <li class="product-sort-criterion input-tree-item item"
                data-criterion="${ criterion }">
                <div class="content">
                    <data id="sort-product-descending-${ index }-label"
                        class="sort-product-descending-label label hidden">descending</data>
                    <data id="sort-product-ascending-${ index }-label"
                        class="sort-product-ascending-label label hidden">ascending</data>
                    <data class="value">${ label }</data>
                </div>
                <button id="sort-product-descending-${ index }-control"
                    class="sort-product-descending-control icon-control control"
                    aria-label="sort products by ${ label } in descending"
                    _="
                        on click
                            add .hidden to #product-preview-tree

                            remove .hidden from .sort-product-descending-control
                            remove .hidden from .sort-product-ascending-control
                            add .hidden to .active-sort-product-spacer
                            add .hidden to .clear-sort-product-control
                            add .hidden to .sort-product-descending-label
                            add .hidden to .sort-product-ascending-label

                            add .hidden to #sort-product-descending-${ index }-control
                            add .hidden to #sort-product-ascending-${ index }-control
                            remove .hidden from #active-sort-product-spacer-${ index }
                            remove .hidden from #clear-sort-product-${ index }-control

                            set criterion to '-${ criterion }'
                            set @data-state of <product-list/> to 'sort'
                            set @data-service of <product-list/> to '/service/data/products/sort?criterion=' + criterion
                    ">
                    <svg class="icon">
                        <use href="/assets/images/feather-sprite.svg#chevrons-down" />
                    </svg>
                </button>
                <button id="sort-product-ascending-${ index }-control"
                    class="sort-product-ascending-control icon-control control"
                    aria-label="sort products by ${ label } in ascending"
                    _="
                        on click
                            add .hidden to #product-preview-tree

                            remove .hidden from .sort-product-descending-control
                            remove .hidden from .sort-product-ascending-control
                            add .hidden to .active-sort-product-spacer
                            add .hidden to .clear-sort-product-control

                            add .hidden to #sort-product-descending-${ index }-control
                            add .hidden to #sort-product-ascending-${ index }-control
                            remove .hidden from #active-sort-product-spacer-${ index }
                            remove .hidden from #clear-sort-product-${ index }-control

                            set criterion to '${ criterion }'
                            set @data-state of <product-list/> to 'sort'
                            set @data-service of <product-list/> to '/service/data/products/sort?criterion=' + criterion
                    ">
                    <svg class="icon">
                        <use href="/assets/images/feather-sprite.svg#chevrons-up" />
                    </svg>
                </button>
                <div id="active-sort-product-spacer-${ index }"
                    class="active-sort-product-spacer spacer hidden"></div>
                <button id="clear-sort-product-${ index }-control"
                    class="clear-sort-product-control icon-control control hidden"
                    aria-label="clear sort ${ label } of products"
                    _="
                        on click
                            remove .hidden from .sort-product-descending-control
                            remove .hidden from .sort-product-ascending-control
                            add .hidden to .active-sort-product-spacer
                            add .hidden to .clear-sort-product-control

                            add .hidden to #active-sort-product-spacer-${ index }
                            add .hidden to #clear-sort-product-${ index }-control
                            remove .hidden from #sort-product-descending-${ index }-control
                            remove .hidden from #sort-product-ascending-${ index }-control

                            set @data-state of <product-list/> to 'list'
                    ">
                    <svg class="icon">
                        <use href="/assets/images/feather-sprite.svg#x" />
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
