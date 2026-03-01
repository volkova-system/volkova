import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Basic/Icon" };
export default meta;

type Story = StoryObj;

export const Icon: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/icon/icon.component.html"
        hx-trigger="load"
        hx-swap="innerHTML">
    </span>
  `
};

export const IconWithLogo: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/icon/icon-with-logo.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const IconWithLetter: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/icon/icon-with-letter.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};

export const IconWithColor: Story = {
  render: () => `
    <span hx-get="/stories/concise/basic/icon/icon-with-color.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
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
