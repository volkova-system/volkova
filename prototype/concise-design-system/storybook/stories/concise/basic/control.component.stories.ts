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
