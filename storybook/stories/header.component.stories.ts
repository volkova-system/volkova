import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Header" };
export default meta;

type Story = StoryObj;

export const PageTreeHeaderBare: Story = {
  render: () => `
    <aside
        class="
            page-tree
            list

            left-sidebar
            sidebar
            bar
        "

        hx-get="/stories/page-tree-header-bare.component.html"
        hx-trigger="load"
        hx-swap="innerHTML"
    >
    </aside>
  `
};

export const PageTreeHeaderWithControl: Story = {
  render: () => `
    <aside
        class="
            page-tree
            list

            left-sidebar
            sidebar
            bar
        "

        hx-get="/stories/page-tree-header-with-control.component.html"
        hx-trigger="load"
        hx-swap="innerHTML"
    >
    </aside>
  `
};

export const PageTreeHeaderWithLogoIcon: Story = {
  render: () => `
    <aside
        class="
            page-tree
            list

            left-sidebar
            sidebar
            bar
        "

        hx-get="/stories/page-tree-header-with-logo-icon.component.html"
        hx-trigger="load"
        hx-swap="innerHTML"
    >
    </aside>
  `
};

export const PageTreeHeaderBase: Story = {
  render: () => `
    <aside
        class="
            page-tree
            list

            left-sidebar
            sidebar
            bar
        "

        hx-get="/stories/page-tree-header-base.component.html"
        hx-trigger="load"
        hx-swap="innerHTML"
    >
    </aside>
  `
};
