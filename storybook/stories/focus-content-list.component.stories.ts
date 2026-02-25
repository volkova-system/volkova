import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Focus Content List" };
export default meta;

type Story = StoryObj;

export const FocusContentListBare: Story = {
  render: () => `
    <article>
    </article>
  `
};
