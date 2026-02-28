import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Profile Picture" };
export default meta;

type Story = StoryObj;

export const ProfilePicture: Story = {
  render: () => `
    <img class="profile-picture picture image"
        src="/assets/images/richeve-bebedor.profile-picture.png"
        alt="Richeve Bebedor Profile Picture"
        aria-label="Richeve Bebedor Profile Picture"
    />
  `
};
