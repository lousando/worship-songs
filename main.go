package main

import (
	"database/sql"
	"errors"
	"fmt"
	"log"
	"github.com/gofiber/template/html/v2"
	"github.com/gofiber/fiber/v3/middleware/static"
	"github.com/gofiber/fiber/v3"
	_ "github.com/tursodatabase/libsql-client-go/libsql"
	"os"
)

func main() {
	// Create a new engine
	viewEngine := html.New("./views", ".tmpl")

	inProduction := os.Getenv("DOTENV_ENV") == "production"

	viewEngine.Reload(!inProduction)
	viewEngine.Debug(!inProduction)

	// for rendering trusted encoded content correctly
	viewEngine.AddFunc("GetSongRowColor", func(index int) string {
		// even
		if index % 2 == 0 {
			return "bg-slate-100 dark:bg-slate-700"
		}

		// odd
		return "bg-slate-300 dark:bg-slate-900"
	})

	app := fiber.New(fiber.Config{
		Views: viewEngine,
	})

	TURSO_DATABASE_URL := os.Getenv("TURSO_DATABASE_URL")
	TURSO_AUTH_TOKEN := os.Getenv("TURSO_AUTH_TOKEN")

	if TURSO_DATABASE_URL == "" {
		log.Fatal("Missing TURSO_DATABASE_URL.")
	}

	if TURSO_AUTH_TOKEN == "" {
		log.Fatal("Missing TURSO_AUTH_TOKEN.")
	}

	dbURL := fmt.Sprintf("%s?authToken=%s", TURSO_DATABASE_URL, TURSO_AUTH_TOKEN)

	db, err := sql.Open("libsql", dbURL)
	if err != nil {
		fmt.Print(err)
		log.Fatal("Failed to open DB.")
	}

	defer db.Close() // close DB at the end

	// static files
	app.Get("/dist/*", static.New("./dist"))

	// health
	app.Get("/api/health", func(c fiber.Ctx) error {
		return c.SendString("OK")
	})

	// external api
	app.Get("/api/songs", func(c fiber.Ctx) error {
		songs, err := getSongs(db, c.Query("name", ""))

		if err != nil {
			fmt.Println(err)
			return c.SendStatus(500)
		}

		return c.JSON(songs)
	})

	// index
	app.Get("/", func(c fiber.Ctx) error {
		songs, err := getSongs(db, c.Query("name", ""))

		if err != nil {
			fmt.Println(err)

			return c.Render("index", fiber.Map{
				"Query": c.Query("name", ""),
				"Songs": []fiber.Map{},
			})
		}

		return c.Render("index", fiber.Map{
			"Query": c.Query("name", ""),
			"Songs": songs,
		})
	})

	// 404 Config
	app.Use(func(c fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).Render("404", fiber.Map{})
	})

	log.Fatal(app.Listen(":8080"))
}

func getSongs (db *sql.DB, query string) ([]fiber.Map, error) {
	rows, err := db.Query("SELECT id,page,name FROM songs WHERE name LIKE ? ORDER BY page", "%" + query + "%")

	if err != nil {
		return []fiber.Map{}, errors.New("failed to fetch songs")
	}

	defer rows.Close()

	// convert to struct
	songs := []fiber.Map{}
	for rows.Next() {
		var page int
		var id, name string

		if err := rows.Scan(&id, &page, &name); err != nil {
			return []fiber.Map{}, errors.New("failed to parse songs")
		}

		songs = append(songs, fiber.Map{
			"Id":   id,
			"Page": page,
			"Name": name,
		})
	}

	if err = rows.Err(); err != nil {
		return []fiber.Map{}, errors.New("row iteration error")
	}

	return songs, nil
}