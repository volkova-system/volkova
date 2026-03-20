import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Precise/Concise Design/Home" };
export default meta;

type Story = StoryObj;

export const ConciseDesignHome: Story = {
  render: () => `
    <div hx-get="/stories/precise/concise-design/pages/concise-design.home-page.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};
