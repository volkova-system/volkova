import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Precise Pages/Richeve Bebedor/Home Page" };
export default meta;

type Story = StoryObj;

export const RicheveBebedorHomePage: Story = {
  render: () => `
    <div hx-get="/pages/richeve-bebedor.home.page.html"
        hx-trigger="load"
        hx-swap="outerHTML"
    >
    </div>
  `
};
