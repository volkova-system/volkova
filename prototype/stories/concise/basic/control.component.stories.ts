import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Basic/Control" };
export default meta;

type Story = StoryObj;

export const ControlWithText: Story = {
    render: () => `
        <div hx-get="/stories/concise/basic/control/control-with-text.component.html"
            hx-trigger="load"
            hx-swap="outerHTML">
        </div>
    `
}

export const ControlWithFocusActionText: Story = {
    render: () => `
        <div hx-get="/stories/concise/basic/control/control-with-focus-action-text.component.html"
            hx-trigger="load"
            hx-swap="outerHTML">
        </div>
    `
}

export const ControlWithSupportActionText: Story = {
    render: () => `
        <div hx-get="/stories/concise/basic/control/control-with-support-action-text.component.html"
            hx-trigger="load"
            hx-swap="outerHTML">
        </div>
    `
}

export const ControlWithOtherActionText: Story = {
    render: () => `
        <div hx-get="/stories/concise/basic/control/control-with-other-action-text.component.html"
            hx-trigger="load"
            hx-swap="outerHTML">
        </div>
    `
}

export const ControlWithSpecificFocusAction: Story = {
  render: () => `
    <div hx-get="/stories/concise/basic/control/control-with-specific-focus-action.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};

export const ControlWithSpecificSupportAction: Story = {
    render: () => `
        <div hx-get="/stories/concise/basic/control/control-with-specific-support-action.component.html"
            hx-trigger="load"
            hx-swap="outerHTML">
        </div>
    `
}

export const ControlWithSpecificOtherAction: Story = {
    render: () => `
        <div hx-get="/stories/concise/basic/control/control-with-specific-other-action.component.html"
            hx-trigger="load"
            hx-swap="outerHTML">
        </div>
    `
}

export const ControlWithIconOnly: Story = {
  render: () => `
    <div hx-get="/stories/concise/basic/control/control-with-icon-only.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};





export const ControlInPageTreeHeader: Story = {
  render: () => `
    <aside class="page-tree list left-sidebar sidebar bar">
        <header class="page-tree-header list-item">
            <span class="header-logo logo-icon icon">
                <svg class="logo-icon icon"
                    viewBox="0 0 900 900"
                    preserveAspectRatio="xMidYMid meet"
                    role="img"
                    aria-label="vs">
                    <use href="/assets/images/vs.logo.svg#vs-logo" />
                </svg>
            </span>
            <a class="header-link link" href="#">
                <h4>volkovasystems</h4>
            </a>
            <div hx-get="/stories/concise/basic/control/control-in-page-tree-header.component.html"
                hx-trigger="load"
                hx-swap="outerHTML">
            </div>
        </header>
    </aside>
  `
};
