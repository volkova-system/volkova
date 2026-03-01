import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Basic/Link" };
export default meta;

type Story = StoryObj;

export const Link: Story = {
  render: () => `
    <a hx-get="/stories/concise/basic/link/link.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </a>
  `
};

export const LinkWithIcon: Story = {
  render: () => `
    <a hx-get="/stories/concise/basic/link/link-with-icon.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </a>
  `
};

export const LinkWithLogo: Story = {
  render: () => `
    <a hx-get="/stories/concise/basic/link/link-with-logo.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </a>
  `
};
