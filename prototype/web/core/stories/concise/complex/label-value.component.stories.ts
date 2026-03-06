import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Complex/Label Value" };
export default meta;

type Story = StoryObj;

export const LabelValue: Story = {
  render: () => `
    <ol hx-get="/stories/concise/complex/label-value/label-value.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </ol>
  `
};
