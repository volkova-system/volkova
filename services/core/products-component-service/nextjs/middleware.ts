import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

/**
 * Middleware to handle CORS (Cross-Origin Resource Sharing) headers.
 * This is the most reliable way to handle CORS in Next.js as it also
 * correctly handles preflight OPTIONS requests before they reach route handlers.
 */
export function middleware(request: NextRequest) {
    const response = NextResponse.next()

    response.headers.set('Access-Control-Allow-Origin', '*')
    response.headers.set('Access-Control-Allow-Methods',
        'GET, POST, PUT, DELETE, OPTIONS')
    response.headers.set('Access-Control-Allow-Headers',
        'Content-Type, Authorization, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Date, X-Api-Version')
    // Cache preflight response for 24 hours
    response.headers.set('Access-Control-Max-Age', '86400')

    // Handle preflight OPTIONS requests
    // Browser sends OPTIONS before the actual request to check permissions
    if (request.method === 'OPTIONS') {
        return new NextResponse(null, {
            status: 204,
            headers: response.headers
        })
    }

    return response
}

// The matcher ensures this middleware only runs for your service routes
export const config = {
    matcher: '/service/component/:path*',
}
