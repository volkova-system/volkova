package models

import "time"

// Product represents the JSON-LD Product schema
type Product struct {
	Context             string              `json:"@context"`
	Type                string              `json:"@type"`
	ID                  string              `json:"@id"`
	SKU                 string              `json:"sku"`
	Name                string              `json:"name"`
	Headline            string              `json:"headline"`
	Description         string              `json:"description"`
	URL                 string              `json:"url"`
	Price               float64             `json:"price"`
	RatingValue         float64             `json:"ratingValue"`
	DiscountPercentage  float64             `json:"discountPercentage"`
	Brand               Brand               `json:"brand"`
	Keywords            []string            `json:"keywords"`
	Image               []string            `json:"image"`
	DateCreated         time.Time           `json:"dateCreated"`
	DateModified        time.Time           `json:"dateModified"`
	AggregateRating     AggregateRating     `json:"aggregateRating"`
	Offers              Offer               `json:"offers"`
	AdditionalProperty  []PropertyValue     `json:"additionalProperty"`
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
