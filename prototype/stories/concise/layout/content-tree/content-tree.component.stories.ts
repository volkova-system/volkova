import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Content Tree" };
export default meta;

type Story = StoryObj;

export const ContentTreeBare: Story = {
  render: () => `
    <main class="content-tree list">
    </main>
  `
};

export const ContentTreeBase: Story = {
  render: () => `
    <main class="content-tree list">
    </main>
  `
};
