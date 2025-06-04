// Package config provides configuration utilities.
package config

import (
	"gotemplaterepo/internal/domain/valueobjects"
)

// Config holds application configuration
type Config struct {
	Example *valueobjects.Example
}

// NewConfig creates a new Config instance
func NewConfig() *Config {
	return &Config{}
}
