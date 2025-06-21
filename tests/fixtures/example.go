package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

// #region Configuration Types
type Config struct {
	Host    string `json:"host"`
	Port    int    `json:"port"`
	Debug   bool   `json:"debug"`
	Timeout int    `json:"timeout"`
}

type DatabaseConfig struct {
	Driver   string `json:"driver"`
	Host     string `json:"host"`
	Port     int    `json:"port"`
	Database string `json:"database"`
	Username string `json:"username"`
	Password string `json:"password"`
}

var defaultConfig = Config{
	Host:    "localhost",
	Port:    8080,
	Debug:   false,
	Timeout: 30,
}

// #endregion

// #region HTTP Handlers
func handleHealth(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"status": "OK",
		"time":   time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func handleAPI(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := map[string]interface{}{
		"message": "API Response",
		"data":    []string{"item1", "item2", "item3"},
		"count":   3,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func handleConfig(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(defaultConfig)
}

// #endregion

// #region Utility Functions
func loadConfig(filepath string) (*Config, error) {
	// Implementation would load from file
	return &defaultConfig, nil
}

func validateConfig(config *Config) error {
	if config.Host == "" {
		return fmt.Errorf("host cannot be empty")
	}
	if config.Port <= 0 {
		return fmt.Errorf("port must be positive")
	}
	return nil
}

func setupRoutes() {
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/api", handleAPI)
	http.HandleFunc("/config", handleConfig)
}

// #endregion

func main() {
	config, err := loadConfig("config.json")
	if err != nil {
		log.Fatal("Failed to load config:", err)
	}

	if err := validateConfig(config); err != nil {
		log.Fatal("Invalid config:", err)
	}

	setupRoutes()

	addr := fmt.Sprintf("%s:%d", config.Host, config.Port)
	log.Printf("Server starting on %s", addr)

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatal("Server failed to start:", err)
	}
}

func init() {
	// This function can be used for any initialization logic
	log.Println("Initializing application...")
}
