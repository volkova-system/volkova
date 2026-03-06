import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Complex/Card Item" };
export default meta;

type Story = StoryObj;

export const CardItemBasic: Story = {
  render: () => `
    <section hx-get="/stories/concise/complex/card-item/card-item.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </section>
  `
};
