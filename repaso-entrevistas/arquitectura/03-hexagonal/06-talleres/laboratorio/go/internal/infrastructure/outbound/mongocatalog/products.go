// Package mongocatalog es el catálogo en MongoDB (parte 3) detrás del mismo puerto Products.
package mongocatalog

import (
	"context"
	"encoding/base64"
	"errors"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"hexorders/internal/application"
	"hexorders/internal/domain"
)

type document struct {
	ID        string `bson:"_id"`
	SKU       string `bson:"sku"`
	Name      string `bson:"name"`
	UnitPrice struct {
		Amount   string `bson:"amount"`
		Currency string `bson:"currency"`
	} `bson:"unitPrice"`
}

type Products struct {
	client *mongo.Client
	coll   *mongo.Collection
}

func Open(ctx context.Context, url string) (*Products, error) {
	client, err := mongo.Connect(options.Client().ApplyURI(url))
	if err != nil {
		return nil, err
	}
	if err := client.Ping(ctx, nil); err != nil {
		return nil, err
	}
	return &Products{client: client, coll: client.Database("hex_catalog").Collection("products")}, nil
}

func (p *Products) Close(ctx context.Context) error { return p.client.Disconnect(ctx) }

func (p *Products) Find(ctx context.Context, sku string) (*domain.Product, error) {
	var doc document
	err := p.coll.FindOne(ctx, bson.M{"_id": sku}).Decode(&doc)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return toProduct(doc)
}

func (p *Products) Exists(ctx context.Context, sku string) (bool, error) {
	n, err := p.coll.CountDocuments(ctx, bson.M{"_id": sku}, options.Count().SetLimit(1))
	return n > 0, err
}

func (p *Products) List(ctx context.Context, page application.PageRequest) (application.Page[domain.Product], error) {
	filter := bson.M{}
	if page.Cursor != "" {
		if raw, err := base64.RawURLEncoding.DecodeString(page.Cursor); err == nil {
			filter["sku"] = bson.M{"$gt": string(raw)}
		}
	}
	cursor, err := p.coll.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "sku", Value: 1}}).SetLimit(int64(page.Limit+1)))
	if err != nil {
		return application.Page[domain.Product]{}, err
	}
	var docs []document
	if err := cursor.All(ctx, &docs); err != nil {
		return application.Page[domain.Product]{}, err
	}
	var next *string
	if len(docs) > page.Limit {
		docs = docs[:page.Limit]
		s := base64.RawURLEncoding.EncodeToString([]byte(docs[len(docs)-1].SKU))
		next = &s
	}
	items := make([]domain.Product, 0, len(docs))
	for _, d := range docs {
		prod, err := toProduct(d)
		if err != nil {
			return application.Page[domain.Product]{}, err
		}
		items = append(items, *prod)
	}
	return application.Page[domain.Product]{Items: items, NextCursor: next}, nil
}

func (p *Products) Save(ctx context.Context, product domain.Product) error {
	_, err := p.coll.UpdateOne(ctx, bson.M{"_id": product.SKU},
		bson.M{"$set": bson.M{"sku": product.SKU, "name": product.Name,
			"unitPrice": bson.M{"amount": product.UnitPrice.Text(), "currency": product.UnitPrice.Currency}}},
		options.UpdateOne().SetUpsert(true))
	return err
}

func toProduct(d document) (*domain.Product, error) {
	price, err := domain.ParseMoney(d.UnitPrice.Amount, d.UnitPrice.Currency)
	if err != nil {
		return nil, err
	}
	return &domain.Product{SKU: d.SKU, Name: d.Name, UnitPrice: price}, nil
}
