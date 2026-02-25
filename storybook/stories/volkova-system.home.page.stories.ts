import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Precise Pages/Volkova System/Home Page" };
export default meta;

type Story = StoryObj;

export const VolkovaSystemHomePage: Story = {
  render: () => `
    <div hx-get="/pages/volkova-system.home.page.html"
        hx-trigger="load"
        hx-swap="outerHTML"
    >
    </div>
  `
};
