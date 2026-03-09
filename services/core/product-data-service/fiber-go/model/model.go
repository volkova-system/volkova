package model

import (
	"time"
)

type Product struct {
	Context             string              `json:"@context"`
	Type                string              `json:"@type"`
	ID                  string              `json:"@id"`

    Reference           string              `json:"reference"`
    SKU                 string              `json:"sku"`
	Name                string              `json:"name"`
	Headline            string              `json:"headline"`
	Description         string              `json:"description"`
	URL                 string              `json:"url"`
	RatingValue         float64             `json:"ratingValue"`

    PriceCurrency       string              `json:"priceCurrency"`
	Price               float64             `json:"price"`
    NetPrice            float64             `json:"netPrice"`
	DiscountPercentage  float64             `json:"discountPercentage"`

    DateCreated         time.Time           `json:"dateCreated"`
	DateModified        time.Time           `json:"dateModified"`

    Thumbnail           string              `json:"thumbnail"`
	Images              []string            `json:"images"`

    Keywords            []string            `json:"keywords"`

    CacheIdentifier     Identifier          `json:"cacheIdentifier"`
    Brand               *Brand              `json:"brand,omitempty"`
	AggregateRating     AggregateRating     `json:"aggregateRating"`
    Offers              Offer               `json:"offers"`
    AdditionalProperty  []PropertyValue     `json:"additionalProperty"`
}

type Identifier struct {
    Type        string   `json:"@type"`
    PropertyID  string   `json:"propertyID"`
    Name        string   `json:"name"`
    Description string   `json:"description"`
    Value       string   `json:"value"`
}

type Brand struct {
	Type string `json:"@type"`
	Name string `json:"name"`
}

type AggregateRating struct {
	Type        string  `json:"@type"`
	RatingValue float64 `json:"ratingValue"`
	BestRating  int     `json:"bestRating"`
	WorstRating int     `json:"worstRating"`
}

type Offer struct {
	Type                string              `json:"@type"`
	PriceCurrency       string              `json:"priceCurrency"`
	Price               float64             `json:"price"`
    NetPrice            float64             `json:"netPrice"`
	Availability        string              `json:"availability"`
	PriceSpecification  PriceSpecification  `json:"priceSpecification"`
	DiscountPercentage  float64             `json:"discountPercentage"`
}

type PriceSpecification struct {
	Type          string  `json:"@type"`
	Price         float64 `json:"price"`
	PriceCurrency string  `json:"priceCurrency"`
}

type PropertyValue struct {
	Type        string `json:"@type"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Value       string `json:"value"`
}
