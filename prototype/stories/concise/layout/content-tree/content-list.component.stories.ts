import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Content Tree" };
export default meta;

type Story = StoryObj;

export const ContentListBare: Story = {
  render: () => `
    <article>
    </article>
  `
};

export const ContentListBase: Story = {
  render: () => `
    <article>
    </article>
  `
};
