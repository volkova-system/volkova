import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Basic/Text" };
export default meta;

type Story = StoryObj;

export const Typography: Story = {
  render: () => `
    <div hx-get="/stories/concise/basic/text/typography.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};
