class ProductList extends HTMLElement {
    connectedCallback() {
        const componentService = this.getAttribute("data-component")
        if (!componentService) return

        const productsComponentServiceAddress = (
            this.getAttribute("data-products-component-service-address")
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
        .then(html => {
            shadow.innerHTML = html

            if (window.htmx) {
                htmx.process(shadow);
            }

            if (window._hyperscript) {
                _hyperscript.processNode(shadow);
            }
        })

        target.replaceWith(shadowHost)
    }
}

customElements.define("product-list", ProductList)
