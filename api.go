package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"cloud.google.com/go/firestore"
)

// APIHandler
func APIHandler(client *firestore.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		//ALLOWING CORS
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		//GETTING CURRENT VALUE
		doc, err := client.Collection("counters").Doc("counter").Get(context.Background())
		if err != nil {
			log.Fatalf("Failed to get document: %v", err)
		}

		value := doc.Data()["value"].(int64)

		//VALUE +1
		value++

		//UPDATING OLD VALUE TO NEW VALUE
		_, err = client.Collection("counters").Doc("counter").Set(context.Background(), map[string]interface{}{
			"value": value,
		}, firestore.MergeAll)
		if err != nil {
			log.Fatalf("Failed to update document: %v", err)
		}
		//NEW VALUE AS JSON TO RESP.
		fmt.Fprintf(w, `{"value": %d}`, value)
	}
}

func main() {
	//FIRESTORE CLIENT
	client, err := firestore.NewClient(context.Background(), "civic-replica-421010")
	if err != nil {
		log.Fatalf("Failed to create Firestore client: %v", err)
	}

	//HANDLER
	http.HandleFunc("/", APIHandler(client))

	//SERVER ON
	port := "8080"
	log.Printf("Listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}
