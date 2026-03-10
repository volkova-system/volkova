class ProductList extends HTMLElement {
    connectedCallback() {
        const componentService = this.getAttribute("data-component")
        if (!componentService) return

        const componentServiceAddress = (
            this.getAttribute("data-component-service-address")
        );
        if (!componentServiceAddress) return

        if (!this.getAttribute("data-service")) return
        const dataService = encodeURIComponent(this.getAttribute("data-service"))

        const targetId = this.getAttribute("target")
        if (!targetId) return

        const target = document.getElementById(targetId)
        if (!target) return

        const url = (
            `${componentServiceAddress}${componentService}?data=${dataService}`
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

customElements.define("product-list", ProductList)
