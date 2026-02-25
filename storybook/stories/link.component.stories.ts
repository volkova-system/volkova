import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Link" };
export default meta;

type Story = StoryObj;

export const LinkBare: Story = {
  render: () => `
    <a class="link" href="https://richeve-bebedor.github.io/">
        <h4>volkovasystems</h4>
    </a>
  `
};

export const LinkWithIcon: Story = {
  render: () => `
    <a class="icon-link link"
        href="https://github.com/volkovasystems"
        target="_blank"
        rel="noopener"
        aria-label="Go to my Github Profile">
        <svg class="icon">
            <use href="/assets/images/feather-sprite.svg#github" />
        </svg>
    </a>
  `
};

export const LinkWithLogo: Story = {
  render: () => `
    <a class="icon-link link"
        href="https://github.com/bebedor-richeve/richeve-bebedor.github.io"
        target="_blank"
        rel="noopener"
        aria-label="Go to richeve-bebedor.github.io Portfolio Repository">
        <svg class="logo-icon icon"
            viewBox="0 0 900 900"
            preserveAspectRatio="xMidYMid meet"
            role="img"
            aria-label="volkovasystems logo">
            <use href="/assets/images/vs.logo.svg#vs-logo" />
        </svg>
    </a>
  `
};
