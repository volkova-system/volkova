class ProductCard extends HTMLElement {
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

        const url = (
            `${productsComponentServiceAddress}${componentService}?data=${dataService}`
        )

        fetch(url)
        .then(response => response.text())
        .then(html => {
            target.innerHTML = html

            if (window.htmx) {
                htmx.process(target);
            }

            if (window._hyperscript) {
                _hyperscript.processNode(target);
            }
        })
    }
}

customElements.define("product-card", ProductCard)
