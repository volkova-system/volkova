import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Precise/KwentoKalakal/Home" };
export default meta;

type Story = StoryObj;

export const KwentoKalakalHome: Story = {
  render: () => `
    <div hx-get="/stories/precise/kwentokalakal/pages/kwentokalakal.home-page.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};
