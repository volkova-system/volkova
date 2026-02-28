import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Icon" };
export default meta;

type Story = StoryObj;

export const IconBare: Story = {
  render: () => `
    <span
        class="icon"

        hx-get="/stories/icon.component.html"
        hx-trigger="load"
        hx-swap="innerHTML"
    />
  `
};

export const IconWithLogo: Story = {
  render: () => `
    <span class="logo-icon icon"

        hx-get="/stories/logo-icon.component.html"
        hx-trigger="load"
        hx-swap="innerHTML"
    />
  `
};

export const IconWithLetter: Story = {
  render: () => `
    <span class="letter-icon icon" role="img" aria-label="volkovasystems">
        <span aria-hidden="true">vs</span>
    </span>
  `
};

export const IconWithColor: Story = {
  render: () => `
    <span class="color-icon icon"
        role="img"
        aria-label="orange">
    </span>
  `
};

export const IconWithLetterColor: Story = {
  render: () => `
    <span class="letter-icon color-icon icon" role="img" aria-label="volkovasystems">
        <span aria-hidden="true">vs</span>
    </span>
  `
};

export const IconWithRoundColor: Story = {
  render: () => `
    <span class="round-icon shape-icon color-icon icon"
        role="img"
        aria-label="round orange">
    </span>
  `
};

export const IconWithSquareColor: Story = {
  render: () => `
    <span class="square-icon shape-icon color-icon icon"
        role="img"
        aria-label="square orange">
    </span>
  `
};

export const IconWithTriangleColor: Story = {
  render: () => `
    <span class="triangle-icon shape-icon color-icon icon"
        role="img"
        aria-label="triangle orange">
    </span>
  `
};

export const IconWithRoundColorBase: Story = {
  render: () => `
    <span
        class="round-icon shape-icon color-icon icon"
        role="img"
        aria-label="svg round color icon"

        hx-get="/stories/icon.component.html"
        hx-trigger="load"
        hx-swap="innerHTML"
    />
  `
};

export const IconWithSquareColorBase: Story = {
  render: () => `
    <span
        class="square-icon shape-icon color-icon icon"
        role="img"
        aria-label="svg square color icon"

        hx-get="/stories/icon.component.html"
        hx-trigger="load"
        hx-swap="innerHTML"
    />
  `
};

export const IconWithTriangleColorBase: Story = {
  render: () => `
    <span
        class="triangle-icon shape-icon color-icon icon"
        role="img"
        aria-label="svg triangle color icon"

        hx-get="/stories/icon.component.html"
        hx-trigger="load"
        hx-swap="innerHTML"
    />
  `
};

export const IconWithRoundLetterColor: Story = {
  render: () => `
    <span
        class="round-icon shape-icon letter-icon color-icon icon"
        role="img"
        aria-label="volkovasystems"
    >
        <span aria-hidden="true">vs</span>
    </span
  `
};

export const IconWithSquareLetterColor: Story = {
  render: () => `
    <span
        class="square-icon shape-icon letter-icon color-icon icon"
        role="img"
        aria-label="volkovasystems"
    >
        <span aria-hidden="true">vs</span>
    </span
  `
};

export const IconWithTriangleLetterColor: Story = {
  render: () => `
    <span
        class="triangle-icon shape-icon letter-icon color-icon icon"
        role="img"
        aria-label="volkovasystems"
    >
        <span aria-hidden="true">vs</span>
    </span
  `
};
