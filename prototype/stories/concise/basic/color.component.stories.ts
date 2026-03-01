import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Basic/Color" };
export default meta;

type Story = StoryObj;

export const ColorRed: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/color/color-red.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const ColorOrange: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/color/color-orange.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const ColorYellow: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/color/color-yellow.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const ColorGreen: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/color/color-green.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const ColorBlue: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/color/color-blue.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const ColorIndigo: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/color/color-indigo.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const ColorViolet: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/color/color-violet.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const ColorWhite: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/color/color-white.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const ColorBlack: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/color/color-black.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};
