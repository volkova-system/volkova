
export interface Identifier {
    '@type': string;
    propertyID: string;
    name: string;
    description: string;
    value: string;
}

export interface Brand {
    '@type': string;
    name: string;
}

export interface AggregateRating {
    '@type': string;
    ratingValue: number;
    bestRating: number;
    worstRating: number;
}

export interface PriceSpecification {
    '@type': string;
    price: number;
    priceCurrency: string;
}

export interface Offer {
    '@type': string;
    priceCurrency: string;
    price: number;
    netPrice: number;
    availability: string;
    priceSpecification: PriceSpecification;
    discountPercentage: number;
}

export interface PropertyValue {
    '@type': string;
    name: string;
    description: string;
    value: string;
}

export interface Product {
    '@context': string;
    '@type': string;
    '@id': string;
    reference: string;
    sku: string;
    name: string;
    headline: string;
    description: string;
    url: string;
    ratingValue: number;
    priceCurrency: string;
    price: number;
    netPrice: number;
    discountPercentage: number;
    dateCreated: string;
    dateModified: string;
    thumbnail: string;
    images: string[];
    keywords: string[];
    cacheIdentifier: Identifier;
    brand?: Brand;
    aggregateRating: AggregateRating;
    offers: Offer;
    additionalProperty: PropertyValue[];
}
