import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Basic/Value" };
export default meta;

type Story = StoryObj;

export const Value: Story = {
  render: () => `
    <data hx-get="/stories/concise/basic/value/value.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </data>
  `
};
