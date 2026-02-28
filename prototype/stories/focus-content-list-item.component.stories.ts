import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Focus Content List Item" };
export default meta;

type Story = StoryObj;

export const FocusContentListItemBare: Story = {
  render: () => `
    <article>
    </article>
  `
};
