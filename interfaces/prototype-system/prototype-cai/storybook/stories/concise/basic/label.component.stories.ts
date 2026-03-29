import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Basic/Label" };
export default meta;

type Story = StoryObj;

export const Label: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/label/label.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};
