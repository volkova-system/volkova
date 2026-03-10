import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Widgets/Product List" };
export default meta;

type Story = StoryObj;

export const ProductList: Story = {
  render: () => `
    <section hx-get="/stories/concise/widgets/product-list/product-list.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </section>
  `
};
