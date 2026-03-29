import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Layout/Content Tree" };
export default meta;

type Story = StoryObj;

export const ContentTree: Story = {
  render: () => `
    <div hx-get="/stories/concise/layout/content-tree/content-tree.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};
