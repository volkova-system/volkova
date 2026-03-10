/** @type {import('next').NextConfig} */
const nextConfig = {
    poweredByHeader: false,
    output: "standalone",
    turbopack: {
        root: __dirname
    }
}

module.exports = nextConfig
