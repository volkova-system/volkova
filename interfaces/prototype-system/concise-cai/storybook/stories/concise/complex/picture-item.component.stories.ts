import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Complex/Picture Item" };
export default meta;

type Story = StoryObj;

export const PictureItemBasic: Story = {
  render: () => `
    <section hx-get="/stories/concise/complex/picture-item/picture-item.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </section>
  `
};
