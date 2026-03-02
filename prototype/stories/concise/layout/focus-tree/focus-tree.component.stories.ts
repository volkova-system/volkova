import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Layout/Focus Tree" };
export default meta;

type Story = StoryObj;

export const FocusTree: Story = {
  render: () => `
    <div hx-get="/stories/concise/layout/focus-tree/focus-tree.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};
