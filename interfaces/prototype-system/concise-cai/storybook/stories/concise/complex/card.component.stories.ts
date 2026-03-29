import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Complex/Card" };
export default meta;

type Story = StoryObj;

export const CardBasic: Story = {
  render: () => `
    <section hx-get="/stories/concise/complex/card/card.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </section>
  `
};
