import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Basic/Picture" };
export default meta;

type Story = StoryObj;

export const Picture: Story = {
  render: () => `
    <img hx-get="/stories/concise/basic/picture/picture.component.html"
        hx-trigger="load"
        hx-swap="outerHTML"
    />
  `
};

export const ProfilePicture: Story = {
  render: () => `
    <img hx-get="/stories/concise/basic/picture/profile-picture.component.html"
        hx-trigger="load"
        hx-swap="outerHTML"
    />
  `
};
