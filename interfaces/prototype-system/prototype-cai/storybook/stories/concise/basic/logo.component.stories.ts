import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Basic/Logo" };
export default meta;

type Story = StoryObj;

export const Logo: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/logo/logo.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const LogoInGrayscale: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/logo/logo-in-grayscale.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const LogoAsInverted: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/logo/logo-as-inverted.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const LogoInGrayscaleAsInverted: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/logo/logo-in-grayscale-as-inverted.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};
