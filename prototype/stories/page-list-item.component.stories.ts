import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Page List Item" };
export default meta;

type Story = StoryObj;

export const PageListItemBare: Story = {
  render: () => `
    <aside
        class="
            page-tree
            list

            left-sidebar
            sidebar
            bar
        "
    >
        <nav hx-get="/stories/page-list-item-bare.component.html"
            hx-trigger="load"
            hx-swap="innerHTML">

        </nav>
    </aside>
  `
};

export const PageListItemWithControl: Story = {
  render: () => `
    <aside
        class="
            page-tree
            list

            left-sidebar
            sidebar
            bar
        "
    >
        <nav hx-get="/stories/page-list-item-with-control.component.html"
            hx-trigger="load"
            hx-swap="innerHTML">
        </nav>
    </aside>
  `
};

export const PageListItemWithIcon: Story = {
  render: () => `
    <aside
        class="
            page-tree
            list

            left-sidebar
            sidebar
            bar
        "
    >
        <nav>
            <ul
                class="
                    page-list
                    list
                "

                hx-get="/stories/page-list-item-with-icon.component.html"
                hx-trigger="load"
                hx-swap="innerHTML"
            >
            </ul>
        </nav>
    </section>
  `
};

export const PageListItemBase: Story = {
  render: () => `
    <aside
        class="
            page-tree
            list

            left-sidebar
            sidebar
            bar
        "
    >
        <nav>
            <ul
                class="
                    page-list
                    list
                "

                hx-get="/stories/page-list-item-base.component.html"
                hx-trigger="load"
                hx-swap="innerHTML"
            >
            </ul>
        </nav>
    </aside>
  `
};
