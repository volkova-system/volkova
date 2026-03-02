import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Precise/MSBUJU/Home" };
export default meta;

type Story = StoryObj;

export const MSBUJUHome: Story = {
  render: () => `
    <div hx-get="/stories/precise/msbuju/pages/msbuju.home-page.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};
