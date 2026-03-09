package model

import (
	"strings"
	"time"

	"github.com/gosimple/slug"
)

type Product struct {
	Context             string              `json:"@context"`
	Type                string              `json:"@type"`
	ID                  string              `json:"@id"`

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
	Images              []string           `json:"images"`

    Keywords            []string            `json:"keywords"`

    CacheIdentifier     Identifier          `json:"cacheIdentifier"`
    Brand               Brand               `json:"brand"`
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

func (product *Product) Normalize() {
    product.Context = "https://schema.org"
	product.Type = "Product"
    product.ID = slug.Make(product.Name + "-" + product.SKU)

    product.SKU = slug.Make(product.SKU)
    product.Name = slug.Make(product.Headline)
    product.Headline = strings.TrimSpace(product.Headline)
    product.Description = strings.TrimSpace(product.Description)
    product.URL = strings.TrimSpace(product.URL)

    product.PriceCurrency = strings.ToLower(strings.TrimSpace(product.PriceCurrency))

    product.CacheIdentifier.Type = "PropertyValue"
    product.CacheIdentifier.PropertyID = "cache:key"
    product.CacheIdentifier.Name = "cache_key"
    product.CacheIdentifier.Value = "product:" + product.ID

    product.Brand.Type = "Brand"
    product.Brand.Name = strings.TrimSpace(product.Brand.Name)

    product.AggregateRating.Type = "AggregateRating"
    product.AggregateRating.RatingValue = product.RatingValue
    product.AggregateRating.BestRating = 5
    product.AggregateRating.WorstRating = 1

    product.Offers.Type = "Offer"
    product.Offers.Availability = "https://schema.org/InStock"
    product.Offers.PriceSpecification.Type = "PriceSpecification"
    product.Offers.PriceSpecification.Price = product.Price
    product.Offers.PriceSpecification.PriceCurrency = product.PriceCurrency
    product.Offers.DiscountPercentage = product.DiscountPercentage

    for index := range product.AdditionalProperty {
        if product.AdditionalProperty[index].Type == "" {
            product.AdditionalProperty[index].Type = "PropertyValue"
            product.AdditionalProperty[index].Name = strings.TrimSpace(
                product.AdditionalProperty[index].Name)
            product.AdditionalProperty[index].Description = strings.TrimSpace(
                product.AdditionalProperty[index].Description)
            product.AdditionalProperty[index].Value = strings.TrimSpace(
                product.AdditionalProperty[index].Value)
        }
    }

    if product.DateCreated.IsZero() {
		product.DateCreated = time.Now().UTC()
	}

    if product.DateModified.IsZero() {
		product.DateModified = time.Now().UTC()
	}
}
