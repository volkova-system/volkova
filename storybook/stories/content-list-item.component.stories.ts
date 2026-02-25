import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Content List Item" };
export default meta;

type Story = StoryObj;

export const ContentListItemBare: Story = {
  render: () => `
    <article>
    </article>
  `
};

export const ContentListItemBase: Story = {
  render: () => `
    <article>
    </article>
  `
};
