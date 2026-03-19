import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Precise/Richeve Bebedor/Home" };
export default meta;

type Story = StoryObj;

export const RicheveBebedorHome: Story = {
  render: () => `
    <section hx-get="/stories/precise/richeve-bebedor/pages/richeve-bebedor.home-page.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </section>
  `
};
