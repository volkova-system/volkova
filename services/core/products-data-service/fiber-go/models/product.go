// Package model defines the data structures for product information
// following JSON-LD schema.org conventions for e-commerce products.
// All structs include JSON tags for proper serialization/deserialization.
package models

import (
	"time"
)

// Product represents a complete product entity following schema.org Product specification.
// It includes all essential product information including pricing, ratings, images,
// and structured data for SEO and data interchange.
type Product struct {
	// JSON-LD context and type information
	Context string `json:"@context"` // JSON-LD context, typically "https://schema.org"
	Type    string `json:"@type"`    // Schema.org type, typically "Product"
	ID      string `json:"@id"`      // Unique identifier for the product

	// Core product information
	Reference   string `json:"reference"`   // Internal product reference/code
	SKU         string `json:"sku"`         // Stock Keeping Unit - unique product identifier
	Name        string `json:"name"`        // Product display name
	Headline    string `json:"headline"`    // Short marketing headline
	Description string `json:"description"` // Detailed product description
	URL         string `json:"url"`         // Product page URL
    BrandName   string `json:"brandName,omitempty"`

	// Rating information
	RatingValue float64 `json:"ratingValue"` // Average rating value

	// Pricing information (duplicated in Offers for schema.org compliance)
	PriceCurrency      string  `json:"priceCurrency"`      // Currency code (e.g., "USD", "EUR")
	Price              float64 `json:"price"`              // Display price including tax
	NetPrice           float64 `json:"netPrice"`           // Price excluding tax
	DiscountPercentage float64 `json:"discountPercentage"` // Discount percentage if applicable

	// Timestamps
	DateCreated  time.Time `json:"dateCreated"`  // Product creation timestamp
	DateModified time.Time `json:"dateModified"` // Last modification timestamp

	// Media assets
	Thumbnail string   `json:"thumbnail"` // Primary thumbnail image URL
	Images    []string `json:"images"`    // Additional product image URLs

	// Categorization and search
	Keywords []string `json:"keywords"` // Search keywords and tags

    SortCriteria []string `json:"sortCriteria"`
    FilterFields []string `json:"filterFields"`

	// Related entities and structured data
	CacheIdentifier    Identifier        `json:"cacheIdentifier"`            // Cache storage identifier
	Brand              *Brand            `json:"brand,omitempty"`            // Product brand information
	AggregateRating    AggregateRating   `json:"aggregateRating"`            // Detailed rating information
	Offers             Offer             `json:"offers"`                     // Pricing and availability offers
	AdditionalProperty []PropertyValue   `json:"additionalProperty"`         // Custom product properties
}

// Identifier represents a structured identifier following schema.org PropertyValue.
// Used for cache keys and other identification purposes within the system.
type Identifier struct {
	Type        string `json:"@type"`        // Schema.org type, typically "PropertyValue"
	PropertyID  string `json:"propertyID"`   // Identifier for the property type
	Name        string `json:"name"`         // Human-readable name of the identifier
	Description string `json:"description"`  // Description of what this identifier represents
	Value       string `json:"value"`        // The actual identifier value
}

// Brand represents product brand information following schema.org Brand specification.
// Contains basic brand identification used for product categorization and display.
type Brand struct {
	Type string `json:"@type"` // Schema.org type, typically "Brand"
	Name string `json:"name"`  // Brand display name
}

// AggregateRating represents aggregated rating information following schema.org AggregateRating.
// Provides detailed rating statistics including value ranges and current rating.
type AggregateRating struct {
	Type        string  `json:"@type"`        // Schema.org type, typically "AggregateRating"
	RatingValue float64 `json:"ratingValue"`  // Current average rating value
	BestRating  int     `json:"bestRating"`   // Maximum possible rating (e.g., 5)
	WorstRating int     `json:"worstRating"`  // Minimum possible rating (e.g., 1)
}

// Offer represents pricing and availability information following schema.org Offer.
// Contains all commercial terms including pricing, currency, and availability status.
type Offer struct {
	Type               string             `json:"@type"`               // Schema.org type, typically "Offer"
	PriceCurrency      string             `json:"priceCurrency"`       // Currency code (ISO 4217)
	Price              float64            `json:"price"`               // Offer price including tax
	NetPrice           float64            `json:"netPrice"`            // Price excluding tax/VAT
	Availability       string             `json:"availability"`        // Availability status (schema.org ItemAvailability)
	PriceSpecification PriceSpecification `json:"priceSpecification"`  // Detailed price breakdown
	DiscountPercentage float64            `json:"discountPercentage"`  // Applied discount percentage
}

// PriceSpecification provides detailed pricing information following schema.org PriceSpecification.
// Used within Offer to specify exact pricing terms and currency.
type PriceSpecification struct {
	Type          string  `json:"@type"`          // Schema.org type, typically "PriceSpecification"
	Price         float64 `json:"price"`          // Specified price amount
	PriceCurrency string  `json:"priceCurrency"`  // Currency for the specified price
}

// PropertyValue represents custom key-value properties following schema.org PropertyValue.
// Used for additional product attributes that don't fit standard schema fields.
type PropertyValue struct {
	Type        string `json:"@type"`        // Schema.org type, typically "PropertyValue"
	Name        string `json:"name"`         // Property name/key
	Description string `json:"description"`  // Property description
	Value       string `json:"value"`        // Property value
}
