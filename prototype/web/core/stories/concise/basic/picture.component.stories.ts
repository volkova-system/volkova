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

export const PictureInProfileSize: Story = {
  render: () => `
    <img hx-get="/stories/concise/basic/picture/picture-in-profile-size.component.html"
        hx-trigger="load"
        hx-swap="outerHTML"
    />
  `
};

export const PictureInThumbnailSize: Story = {
  render: () => `
    <img hx-get="/stories/concise/basic/picture/picture-in-thumbnail-size.component.html"
        hx-trigger="load"
        hx-swap="outerHTML"
    />
  `
};
