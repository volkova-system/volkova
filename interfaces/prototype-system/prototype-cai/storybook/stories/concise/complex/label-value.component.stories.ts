import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Complex/Label Value" };
export default meta;

type Story = StoryObj;

export const LabelValue: Story = {
  render: () => `
    <section hx-get="/stories/concise/complex/label-value/label-value.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </section>
  `
};

export const LabelValueWithIcon: Story = {
  render: () => `
    <section hx-get="/stories/concise/complex/label-value/label-value-with-icon.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </section>
  `
};
