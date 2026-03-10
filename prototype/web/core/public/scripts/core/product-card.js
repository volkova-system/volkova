class ProductCard extends HTMLElement {
    connectedCallback() {
        const targetId = this.getAttribute("target")
        const componentService = this.getAttribute("data-component")
        const dataService = this.getAttribute("data-service")

        const target = document.getElementById(targetId)

        if (!targetId) return
        if (!componentService) return
        if (!dataService) return
        if (!target) return

        const shadowHost = document.createElement("div")
        const shadow = shadowHost.attachShadow({ mode: "open" })

        fetch(`${componentService}?data=${encodeURIComponent(dataService)}`)
        .then(response => response.text())
        .then(html => {shadow.innerHTML = html})

        target.replaceWith(shadowHost)
    }
}

customElements.define("product-card", ProductCard)
