package main

import (
	"database/sql"
	"log"
	"net/http"
)

// #region Configuration Constants
const (
	host     = "localhost"
	port     = 3000
	dbDriver = "postgres"
)

// #endregion

// #region Database Types
type User struct {
	ID       int    `json:"id"`
	Username string `json:"username"`
	Email    string `json:"email"`
}

type Database struct {
	conn *sql.DB
}

// #endregion

// #region Database Methods
func NewDatabase(dsn string) (*Database, error) {
	conn, err := sql.Open(dbDriver, dsn)
	if err != nil {
		return nil, err
	}
	return &Database{conn: conn}, nil
}

func (db *Database) GetUser(id int) (*User, error) {
	user := &User{}
	err := db.conn.QueryRow("SELECT id, username, email FROM users WHERE id = $1", id).
		Scan(&user.ID, &user.Username, &user.Email)
	return user, err
}

// #endregion

// #region HTTP Handlers
func handleGetUser(db *Database) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Handler implementation
		log.Println("Handling user request")
	}
}

func handleCreateUser(db *Database) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Handler implementation
		log.Println("Creating new user")
	}
}

// #endregion

func main() {
	// #region Server Setup
	db, err := NewDatabase("postgres://localhost:5432/myapp?sslmode=disable")
	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/user", handleGetUser(db))
	http.HandleFunc("/user/create", handleCreateUser(db))

	log.Printf("Server starting on :%d", port)
	log.Fatal(http.ListenAndServe(":3000", nil))
	// #endregion
}
