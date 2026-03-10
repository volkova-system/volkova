class ProductList extends HTMLElement {
    connectedCallback() {
        const componentService = this.getAttribute("data-component")
        if (!componentService) return

        const productsComponentServiceAddress = (
            document.querySelector(
                'meta[name="products-component-service-address"]'
            ).content
        );
        if (!productsComponentServiceAddress) return

        if (!this.getAttribute("data-service")) return
        const dataService = encodeURIComponent(this.getAttribute("data-service"))

        const targetId = this.getAttribute("target")
        if (!targetId) return

        const target = document.getElementById(targetId)
        if (!target) return

        const shadowHost = document.createElement("div")
        const shadow = shadowHost.attachShadow({ mode: "open" })

        const url = (
            `${productsComponentServiceAddress}${componentService}?data=${dataService}`
        )

        fetch(url)
        .then(response => response.text())
        .then(html => {shadow.innerHTML = html})

        target.replaceWith(shadowHost)
    }
}

customElements.define("product-list", ProductList)
