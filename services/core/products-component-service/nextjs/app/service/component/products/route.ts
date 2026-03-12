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
                    <dd class="subtitle discount value"
                        >${ Math.ceil(product.discountPercentage) }</dd>
                </dl>
            </li>
            <li class="normal-spacing item spacer"></li>
        `
    }).join("")

    let dataServicePathNext = searchParams.get("data") || ""
    let skipNext = dataProducts.skip + dataProducts.limit
    if ((dataProducts.page + 1) > dataProducts.pages) skipNext = 0
    if (dataServicePathNext.includes("&skip="))
        dataServicePathNext = dataServicePathNext
        ?.replace(/\&skip\=\d+/,`&skip=${ skipNext }`)
    else if (dataServicePathNext.includes("?skip="))
        dataServicePathNext = dataServicePathNext
        ?.replace(/\?skip\=\d+/,`?skip=${ skipNext }`)
    else if (dataServicePathNext.includes("?"))
        dataServicePathNext += `&skip=${ skipNext }`
    else dataServicePathNext += `?skip=${ skipNext }`

    let dataServicePathBack = searchParams.get("data") || ""
    let skipBack = dataProducts.skip - dataProducts.limit
    if (skipBack < 0) skipBack = dataProducts.limit * (dataProducts.pages - 1)
    if (dataServicePathBack.includes("&skip="))
        dataServicePathBack = dataServicePathBack
        ?.replace(/\&skip\=\d+/,`&skip=${ skipBack }`)
    else if (dataServicePathBack.includes("?skip="))
        dataServicePathBack = dataServicePathBack
        ?.replace(/\?skip\=\d+/,`?skip=${ skipBack }`)
    else if (dataServicePathBack.includes("?"))
        dataServicePathBack += `&skip=${ skipBack }`
    else dataServicePathBack += `?skip=${ skipBack }`

    const html = `
        <ol class="product-list content-tree-list list">
            ${ productList }
             <li id="product-list-pagination"
                class="content-tree-item item
                    ${ dataProducts.pages <= 1 ? 'hidden': '' }">
                <div class="spacer hidden"></div>
                <button class="icon-control control"
                    aria-label="go back last page"
                    _="
                        on click
                            set @data-service of <product-list/> to '${ dataServicePathBack }'
                    ">
                    <svg class="icon">
                        <use href="/assets/images/feather-sprite.svg#chevron-up" />
                    </svg>
                </button>
                <div class="spacer hidden"></div>
                <div class="content">
                    <data class="value"
                        >${ dataProducts.page } / ${ dataProducts.pages }</data>
                </div>
                <button class="icon-control control"
                    aria-label="go to next page"
                    _="
                        on click
                            set @data-service of <product-list/> to '${ dataServicePathNext }'
                    ">
                    <svg class="icon">
                        <use href="/assets/images/feather-sprite.svg#chevron-down" />
                    </svg>
                </button>
             </li>
        </ol>
    `

    return new Response(html, {
        headers: {
            "Content-Type": "text/html"
        }
    })
}
