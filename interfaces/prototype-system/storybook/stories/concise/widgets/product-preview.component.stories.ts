import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Widgets/Product Preview" };
export default meta;

type Story = StoryObj;

export const ProductPreviewBasic: Story = {
  render: () => `
    <section hx-get="/stories/concise/widgets/product-preview/product-preview.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </section>
  `
};
